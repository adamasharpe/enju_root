class AttachmentFile < ActiveRecord::Base
  include LibrarianRequired
  #include ExtractContent
  named_scope :not_indexed, :conditions => ['indexed_at IS NULL']
  belongs_to :manifestation
  has_one :db_file

  named_scope :pictures, :conditions => {:content_type => ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png']}
  default_scope :order => 'id DESC'

  has_attachment
  validates_as_attachment
  validates_presence_of :manifestation
  validates_associated :manifestation

  #acts_as_scribd_document
  enju_scribd

  cattr_accessor :per_page
  @@per_page = 10
  attr_accessor :title
  
  #before_save :extract_text

  def before_validation_on_create
    unless self.manifestation
      manifestation = Manifestation.create!(:original_title => self.title, :manifestation_form => ManifestationForm.find(:first, :conditions => {:name => 'file'}), :post_to_twitter => false)
      self.manifestation_id = manifestation.id
    end
  end

  def extract_text
    content = Tempfile::new("content")
    content.puts(self.db_file.data)
    content.close
    text = Tempfile::new("text")
    case self.content_type
    when "application/pdf"
      system("pdftotext -q -enc UTF-8 -raw #{content.path} #{text.path}")
    when "application/msword"
      system("antiword #{content.path} 2> /dev/null > #{text.path}")
    # TODO: HTMLのタグの除去
    when "application/vnd.ms-excel"
      system("xlhtml #{content.path} 2> /dev/null > #{text.path}")
    when "application/vnd.ms-powerpoint"
      system("ppthtml #{content.path} 2> /dev/null > #{text.path}")
#    when "text/html"
#      system("elinks --dump 1 #{self.full_filename} 2> /dev/null #{temp.path}")
    #  html = open(self.full_filename).read
    #  body, title = ExtractContent::analyse(html)
    #  body = NKF.nkf('-w', body)
    #  title = NKF.nkf('-w', title)
    #  temp.open
    #  temp.puts(title)
    #  temp.puts(body)
    #  temp.close
    #else
    #  nil
    end

    self.fulltext = text.read
    self.indexed_at = Time.zone.now
    self.save
    text.close
  #rescue
  #  nil
  end

  def self.extract_text
    AttachmentFile.not_indexed.find_each do |file|
      file.extract_text
    end
  end

  def digest(options = {:type => 'sha1'})
    if self.file_hash.blank?
      self.file_hash = Digest::SHA1.hexdigest(self.db_file.data)
    end
    self.file_hash
  end

end
