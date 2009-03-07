class ImportedResourceFile < ActiveRecord::Base
  include LibrarianRequired
  named_scope :not_imported, :conditions => {:imported_at => nil}

  has_attachment :content_type => ['text/csv', 'text/plain', 'text/tab-separated-values']
  validates_as_attachment
  belongs_to :user
  has_many :imported_objects, :as => :importable, :dependent => :destroy
  has_one :imported_object, :as => :imported_file, :dependent => :destroy

  def import
    self.reload
    reader = CSV::Reader.create(self.db_file.data, "\t")
    header = reader.shift
    num = 0
    reader.each do |row|
      data = {}
      row.each_with_index { |cell, j| data[header[j].to_s.strip] = cell.to_s.strip }
      begin
        library = Library.find(:first, :conditions => {:short_name => data['library_short_name'].chomp})
      rescue
        library = Library.find(1) if library.nil?
      end

      # ISBNが入力してあればそれを優先する
      if data['isbn']
        manifestation = Manifestation.import_isbn(data['isbn']) rescue nil
      end

      if manifestation.nil?
        ImportedResourceFile.transaction do
          begin
            authors = data['author'].split
            publishers = data['publisher'].split
            author_patrons = Manifestation.import_patrons(authors)
            publisher_patrons = Manifestation.import_patrons(publishers)

            work = Work.new
            work.restrain_indexing = true
            work.original_title = data['title'].chomp
            if work.save!
              work.patrons << author_patrons
              imported_object = ImportedObject.new
              imported_object.importable = work
              imported_object.import_file = self
              imported_object.save
            end

            expression = Expression.new
            expression.restrain_indexing = true
            expression.original_title = work.original_title
            expression.work = work
            if expression.save!
              imported_object = ImportedObject.new
              imported_object.importable = expression
              imported_object.import_file = self
              imported_object.save
            end

            manifestation = Manifestation.new
            manifestation.restrain_indexing = true
            manifestation.original_title = expression.original_title
            manifestation.expressions << expression
            if manifestation.save!
              manifestation.patrons << author_patrons
              imported_object= ImportedObject.new
              imported_object.importable = manifestation
              imported_object.import_file = self
              imported_object.save
            end

            item = Item.new
            item.restrain_indexing = true
            item.manifestation = manifestation
            if item.save!
              item.patrons << library.patron
              imported_object= ImportedObject.new
              imported_object.importable = item
              imported_object.import_file = self
              imported_object.save
            end

            num += 1
            GC.start if num % 50 == 0
          rescue
            nil
          end
        end
      end
    end
    return num
  end

  def import_marc(marc_file, marc_type)
    case marc_type
    when 'marcxml'
      reader = MARC::XMLReader.new(StringIO.new(marc_file.read))
    else
      reader = MARC::Reader.new(StringIO.new(marc_file.read))
    end

    # when 'marc_xml_url'
    #  url = URI(params[:marc_xml_url])
    #  xml = open(url).read
    #  reader = MARC::XMLReader.new(StringIO.new(xml))
    #end

    # TODO
    for record in reader
      work = Work.new(:title => record['245']['a'])
      work.work_form = WorkForm.find(1)
      work.restrain_indexing = true
      work.save

      expression = Expression.new(:title => work.original_title)
      expression.expression_form = ExpressionForm.find(1)
      expression.language = Language.find(1)
      expression.frequency_of_issue = FrequencyOfIssue.find(1)
      expression.restrain_indexing = true
      expression.save
      work.expressions << expression

      manifestation = Manifestation.new(:title => expression.original_title)
      manifestation.manifestation_form = ManifestationForm.find(1)
      manifestation.language = Language.find(1)
      manifestation.restrain_indexing = true
      manifestation.save
      expression.manifestations << manifestation

      full_name = record['700']['a']
      publisher = Patron.find_by_full_name(record['700']['a'])
      if publisher.blank?
        publisher = Patron.new(:full_name => full_name)
        publisher.restrain_indexing = true
        publisher.save
      end
      manifestation.patrons << publisher
    end
  end

end
