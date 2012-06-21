class ResourceImportFile < ActiveRecord::Base
  default_scope :order => 'id DESC'
  scope :not_imported, where(:state => 'pending', :imported_at => nil)

  if configatron.uploaded_file.storage == :s3
    has_attached_file :resource_import, :storage => :s3, :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
      :path => "resource_import_files/:id/:filename"
  else
    has_attached_file :resource_import, :path => ":rails_root/private:url"
  end
  validates_attachment_content_type :resource_import, :content_type => ['text/csv', 'text/plain', 'text/tab-separated-values', 'application/octet-stream']
  validates_attachment_presence :resource_import
  belongs_to :user, :validate => true
  has_many :resource_import_results

  state_machine :initial => :pending do
    event :sm_start do
      transition [:pending, :started] => :started
    end

    event :sm_complete do
      transition :started => :completed
    end

    event :sm_fail do
      transition :started => :failed
    end
  end

  def import_start
    sm_start!
    import
  end

  def import
    self.reload
    num = {:found => 0, :success => 0, :failure => 0}
    row_num = 2
    rows = self.open_import_file
    field = rows.first
    if [field['isbn'], field['original_title']].reject{|field| field.to_s.strip == ""}.empty?
      raise "You should specify isbn or original_tile in the first line"
    end

    rows.each do |row|
      import_result = ResourceImportResult.create!(:resource_import_file => self, :body => row.fields.join("\t"))

      item_identifier = row['item_identifier'].to_s.strip
      if item = Item.where(:item_identifier => item_identifier).first
        import_result.item = item
        import_result.save!
        next
      end

      manifestation = fetch(row)
      import_result.manifestation = manifestation

      begin
        if manifestation and item_identifier.present?
          import_result.item = create_item(row, manifestation)
           Rails.logger.info("resource registration succeeded: column #{row_num}"); next
           num[:success] += 1
        else
          if manifestation
            Rails.logger.info("item found: isbn #{row['isbn']}")
            num[:found] += 1
          else
            num[:failure] += 1
          end
        end
      rescue Exception => e
        Rails.logger.info("resource registration failed: column #{row_num}: #{e.message}")
      end

      import_result.save!
      if row_num % 50 == 0
        Sunspot.commit
        GC.start
      end
      row_num += 1
    end

    self.update_attribute(:imported_at, Time.zone.now)
    Sunspot.commit
    rows.close
    sm_complete!
    Rails.cache.write("manifestation_search_total", Manifestation.search.total)
    return num
  end

  def self.import_work(title, patrons, series_statement)
    work = Work.create(title)
    if series_statement
      work.series_statement = series_statement
    end
    work.patrons << patrons
    work
  end

  def self.import_expression(work, patrons)
    expression = Expression.new(
      :original_title => work.original_title,
      :title_transcription => work.title_transcription,
      :title_alternative => work.title_alternative
    )
    work.expressions << expression
    expression.patrons << patrons
    expression
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

  def remove
    rows = self.open_import_file
    field = rows.first
    rows.each do |row|
      item_identifier = row['item_identifier'].to_s.strip
      if item = Item.where(:item_identifier => item_identifier).first
        item.destroy
      end
    end
  end

  def open_import_file
    if RUBY_VERSION > '1.9'
      if configatron.uploaded_file.storage == :s3
        file = CSV.open(open(self.resource_import.url).path, :col_sep => "\t")
        header = file.first
        rows = CSV.open(open(self.resource_import.url).path, :headers => header, :col_sep => "\t")
      else
        file = CSV.open(self.resource_import.path, :col_sep => "\t")
        header = file.first
        rows = CSV.open(self.resource_import.path, :headers => header, :col_sep => "\t")
      end
    else
      if configatron.uploaded_file.storage == :s3
        file = FasterCSV.open(open(self.resource_import.url).path, :col_sep => "\t")
        header = file.first
        rows = FasterCSV.open(open(self.resource_import.url).path, :headers => header, :col_sep => "\t")
      else
        file = FasterCSV.open(self.resource_import.path, :col_sep => "\t")
        header = file.first
        rows = FasterCSV.open(self.resource_import.path, :headers => header, :col_sep => "\t")
      end
    end
    ResourceImportResult.create(:resource_import_file => self, :body => header.join("\t"))
    file.close
    rows
  end

  private
  def import_subject(row)
    subjects = []
    row['subject'].to_s.split(';').each do |s|
      unless subject = Subject.where(:term => s.to_s.strip).first
        # TODO: Subject typeの設定
        subject = Subject.create(:term => s.to_s.strip, :subject_type_id => 1)
      end
      subjects << subject
    end
    subjects
  end

  def create_item(row, manifestation)
    circulation_status = CirculationStatus.where(:name => row['circulation_status'].to_s.strip).first || CirculationStatus.where(:name => 'In Process').first
    shelf = Shelf.where(:name => row['shelf'].to_s.strip).first || Shelf.web
    item = self.class.import_item(manifestation, {
      :item_identifier => row['item_identifier'],
      :price => row['item_price'],
      :call_number => row['call_number'].to_s.strip,
      :circulation_status => circulation_status,
      :shelf => shelf
    })
    item
  end

  def fetch(row)
    shelf = Shelf.where(:name => row['shelf'].to_s.strip).first || Shelf.web

    unless row['identifier'].blank?
      if manifestation = Manifestation.where(:identifier => row['identifier'].to_s.strip).first
        return manifestation
      end
    end

    unless row['isbn'].blank?
      isbn = StdNum::ISBN.normalize(row['isbn'])
      unless manifestation = Manifestation.find_by_isbn(isbn)
        manifestation = Manifestation.import_isbn!(isbn) rescue nil
        #num[:success] += 1 if manifestation
      end
      return manifestation if manifestation
    end

    title = {}
    title[:original_title] = row['original_title']
    title[:title_transcription] = row['title_transcription']
    title[:title_alternative] = row['title_alternative']
    #title[:title_transcription_alternative] = row['title_transcription_alternative']
    return nil if title[:original_title].blank?

    ResourceImportFile.transaction do
      unless manifestation
        authors = row['author'].to_s.split(';')
        contributors = row['contributor'].to_s.split(';')
        publishers = row['publisher'].to_s.split(';')
        author_patrons = Patron.import_patrons(authors)
        contributor_patrons = Patron.import_patrons(contributors)
        publisher_patrons = Patron.import_patrons(publishers)
        #classification = Classification.first(:conditions => {:category => row['classification'].to_s.strip)
        subjects = import_subject(row)
        series_statement = import_series_statement(row)

        #work = self.class.import_work(title, author_patrons, row['series_statment_id'])
        #work.subjects << subjects
        #expression = self.class.import_expression(work, contributor_patrons)

        lisbn = Lisbn.new(row['isbn'].to_s.strip)
        if lisbn.isbn.valid?
          isbn = lisbn.isbn
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

        manifestation = Manifestation.create(
          :original_title => title[:original_title],
          :title_transcription => title[:title_transcription],
          :title_alternative => title[:title_alternative],
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
          :identifier => row['identifier']
        )
      end

      if manifestation.valid?
        manifestation.patrons << publisher_patrons
        if manifestation.similar_works.present?
          work = manifestation.similar_works.first
        else
          work = ResourceImportFile.import_work(title, author_patrons, series_statement)
        end
        expression = ResourceImportFile.import_expression(work, contributor_patrons) if work.valid?
        expression.manifestations << manifestation if expression.valid?
      end
    end

    manifestation
  end

  def import_series_statement(row)
    unless series_statement = SeriesStatement.where(:series_statement_identifier => row['series_statement_identifier'].to_s.strip).first
      if row['series_statement_original_title'].to_s.strip.present?
        series_statement = SeriesStatement.create(
          :original_title => row['series_statement_original_title'].to_s.strip,
          :title_transcription => row['series_statement_title_transcription'].to_s.strip,
          :series_statement_identifier => row['series_statement_identifier'].to_s.strip
        )
      end
    end
  end
end
# == Schema Information
#
# Table name: resource_import_files
#
#  id                           :integer         not null, primary key
#  parent_id                    :integer
#  filename                     :string(255)
#  content_type                 :string(255)
#  size                         :integer
#  file_hash                    :string(255)
#  user_id                      :integer
#  note                         :text
#  imported_at                  :datetime
#  state                        :string(255)
#  resource_import_file_name    :string(255)
#  resource_import_content_type :string(255)
#  resource_import_file_size    :integer
#  resource_import_updated_at   :datetime
#  created_at                   :datetime        not null
#  updated_at                   :datetime        not null
#  resource_import_fingerprint  :string(255)
#

