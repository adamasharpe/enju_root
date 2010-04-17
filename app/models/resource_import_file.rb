class ResourceImportFile < ActiveRecord::Base
  include AASM
  include LibrarianRequired
  default_scope :order => 'id DESC'
  named_scope :not_imported, :conditions => {:state => 'pending', :imported_at => nil}

  has_attached_file :resource_import, :path => ":rails_root/private:url"
  validates_attachment_content_type :resource_import, :content_type => ['text/csv', 'text/plain', 'text/tab-separated-values', 'application/octet-stream']
  validates_attachment_presence :resource_import
  belongs_to :user, :validate => true
  has_many :imported_objects, :as => :imported_file, :dependent => :destroy

  aasm_column :state
  aasm_initial_state :pending
  aasm_state :pending
  aasm_state :started
  aasm_state :failed
  aasm_state :completed

  aasm_event :aasm_import do
    transitions :from => :started, :to => :completed,
      :on_transition => :import
  end
  aasm_event :aasm_import_start do
    transitions :from => :pending, :to => :started
  end
  aasm_event :aasm_fail do
    transitions :from => :started, :to => :failed
  end

  def after_create
  #  set_digest
  end

  def set_digest(options = {:type => 'sha1'})
    self.file_hash = Digest::SHA1.hexdigest(File.open(self.resource_import.path, 'rb').read)
    save(false)
  end

  def import_start
    aasm_import_start!
    aasm_import!
  end

  def import
    unless /text\/.+/ =~ FileWrapper.get_mime(resource_import.path)
      aasm_fail!
      raise 'Invalid format'
    end
    self.reload
    num = {:found => 0, :success => 0, :failure => 0}
    record = 2
    file = FasterCSV.open(self.resource_import.path, :col_sep => "\t")
    rows = FasterCSV.open(self.resource_import.path, :headers => file.first, :col_sep => "\t")
    file.close
    field = rows.first
    if [field['isbn'], field['original_title']].reject{|field| field.to_s.strip == ""}.empty?
      raise "You should specify isbn or original_tile in the first line"
    end
    #rows.shift
    rows.each do |row|
      shelf = Shelf.first(:conditions => {:name => row['shelf'].to_s.strip}) || Shelf.web

      # タイトルが入力してあればそれを優先する
      if row['isbn']
        unless manifestation = Manifestation.find_by_isbn(row['isbn'].to_s.strip)
          if row['original_title'].to_s.strip.blank?
            manifestation = Manifestation.import_isbn!(row['isbn'].to_s.strip) rescue nil
            save_imported_object(manifestation)
            #num[:success] += 1 if manifestation
          end
        end
      end

      title = {}
      title[:original_title] = row['original_title']
      title[:title_transcription] = row['title_transcription']
      title[:title_alternative] = row['title_alternative']
      #title[:title_transcription_alternative] = row['title_transcription_alternative']

      ResourceImportFile.transaction do
        if manifestation.nil?
          #begin
            authors = row['author'].to_s.split(';')
            publishers = row['publisher'].to_s.split(';')
            author_patrons = Manifestation.import_patrons(authors)
            publisher_patrons = Manifestation.import_patrons(publishers)
            #classification = Classification.first(:conditions => {:category => row['classification'].to_s.strip)
            subjects = []
            row['subject'].to_s.split(';').each do |s|
              unless subject = Subject.first(:conditions => {:term => s.to_s.strip})
                # TODO: Subject typeの設定
                subject = Subject.create(:term => s.to_s.strip, :subject_type_id => 1)
              end
              subjects << subject
            end
            unless series_statement = SeriesStatement.first(:conditions => {:series_statement_identifier => row['series_statement_identifier'].to_s.strip})
              if row['series_statement_original_title'].to_s.strip.present?
                series_statement = SeriesStatement.create(
                  :original_title => row['series_statement_original_title'].to_s.strip,
                  :title_transcription => row['series_statement_title_transcription'].to_s.strip,
                  :series_statement_identifier => row['series_statement_identifier'].to_s.strip
                )
              end
            end

            work = self.class.import_work(title, author_patrons, row['series_statment_id'])
            work.subjects << subjects
            save_imported_object(work)
            expression = self.class.import_expression(work)
            save_imported_object(expression)

            if ISBN_Tools.is_valid?(row['isbn'].to_s.strip)
              isbn = row['isbn']
            end
            date_of_publication = Time.zone.parse(row['date_of_publication']) rescue nil
            # TODO: 小数点以下の表現
            height = NKF.nkf('-eZ1', row['height'].to_s).gsub(/\D/, '').to_i
            end_page = NKF.nkf('-eZ1', row['number_of_pages'].to_s).gsub(/\D/, '').to_i
            if end_page >= 1
              start_page = 1
            else
              start_page = nil
              end_page = nil
            end

            manifestation = self.class.import_manifestation(expression, publisher_patrons, {
              :isbn => isbn,
              :wrong_isbn => row['wrong_isbn'],
              :issn => row['issn'],
              :lccn => row['lccn'],
              :nbn => row['nbn'],
              :date_of_publication => date_of_publication,
              :volume_number_list => row['volume_number_list'],
              :edition => row['edition'],
              :height => row['height'],
              :price => row['manifestation_price'],
              :description => row['description'],
              :note => row['note'],
              :series_statement => series_statement,
              :height => height,
              :start_page => start_page,
              :end_page => end_page,
              :manifestation_identifier => row['manifestation_identifier']
            })
            save_imported_object(manifestation)

            Rails.logger.info("resource import succeeded: column #{record}")
          #rescue Exception => e
          #  Rails.logger.info("resource import failed: column #{record}: #{e.message}")
          #  num[:failure] += 1
          #end
        end

        begin
          if manifestation
            unless item = Item.first(:conditions => {:item_identifier => row['item_identifier'].to_s.strip})
              circulation_status = CirculationStatus.first(:conditions => {:name => row['circulation_status'].to_s.strip}) || CirculationStatus.first(:conditions => {:name => 'In Process'})
              shelf = Shelf.first(:conditions => {:name => row['shelf'].to_s.strip}) || Shelf.web
              item = self.class.import_item(manifestation, {
                :item_identifier => row['item_identifier'],
                :price => row['item_price'],
                :call_number => row['call_number'].to_s.strip,
                :circulation_status => circulation_status,
                :shelf => shelf
              })
              save_imported_object(item)
              num[:success] += 1
              Rails.logger.info("resource registration succeeded: column #{record}"); next
            else
              Rails.logger.info("resource found: isbn #{row['isbn']}")
              num[:found] += 1
            end
          end
        rescue Exception => e
          Rails.logger.info("resource registration failed: column #{record}: #{e.message}")
        end
        GC.start if record % 50 == 0
      end
      record += 1
    end
    self.update_attribute(:imported_at, Time.zone.now)
    Sunspot.commit
    rows.close
    Rails.cache.delete("Manifestation.search.total")
    return num
  end

  def self.import_work(title, patrons, series_statement_id)
    work = Work.new(title)
    if series_statement = SeriesStatement.find(series_statement_id) rescue nil
      work.series_statement = series_statement
    end
    #if work.save!
      work.patrons << patrons
    #end
    return work
  end

  def self.import_expression(work)
    expression = Expression.new(
      :original_title => work.original_title,
      :title_transcription => work.title_transcription,
      :title_alternative => work.title_alternative
    )
    #if expression.save!
      work.expressions << expression
    #end
    return expression
  end

  def self.import_manifestation(expression, patrons, options = {})
    manifestation = Manifestation.new(options)
    manifestation.original_title = expression.original_title
    #if manifestation.save!
      manifestation.expressions << expression
      manifestation.patrons << patrons
    #end
    return manifestation
  end

  def self.import_item(manifestation, options)
    options = {:shelf => Shelf.web}.merge(options)
    item = Item.new(options)
    #if item.save!
      manifestation.items << item
      item.patrons << options[:shelf].library.patron
    #end
    return item
  end

  def save_imported_object(record)
    imported_object = ImportedObject.new
    imported_object.importable = record
    imported_objects << imported_object
  end

  def import_marc(marc_type)
    file = File.open(self.resource_import.path)
    case marc_type
    when 'marcxml'
      reader = MARC::XMLReader.new(file)
    else
      reader = MARC::Reader.new(file)
    end
    file.close

    #when 'marc_xml_url'
    #  url = URI(params[:marc_xml_url])
    #  xml = open(url).read
    #  reader = MARC::XMLReader.new(StringIO.new(xml))
    #end

    # TODO
    for record in reader
      work = Work.new(:original_title => record['245']['a'])
      work.form_of_work = FormOfWork.find(1)
      work.save

      expression = Expression.new(:original_title => work.original_title)
      expression.content_type = ContentType.find(1)
      expression.language = Language.find(1)
      expression.save
      work.expressions << expression

      manifestation = Manifestation.new(:original_title => expression.original_title)
      manifestation.carrier_type = CarrierType.find(1)
      manifestation.frequency = Frequency.find(1)
      manifestation.language = Language.find(1)
      manifestation.save
      expression.manifestations << manifestation

      full_name = record['700']['a']
      publisher = Patron.find_by_full_name(record['700']['a'])
      if publisher.blank?
        publisher = Patron.new(:full_name => full_name)
        publisher.save
      end
      manifestation.patrons << publisher
    end
  end

  def self.import
    ResourceImportFile.not_imported.each do |file|
      file.import_start
    end
  rescue
    logger.info "#{Time.zone.now} importing resources failed!"
  end

  #def import_jpmarc
  #  marc = NKF::nkf('-wc', self.db_file.data)
  #  marc.split("\r\n").each do |record|
  #  end
  #end

end
