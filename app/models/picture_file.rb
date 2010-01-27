class PictureFile < ActiveRecord::Base
  include OnlyLibrarianCanModify
  named_scope :attached, :conditions => ['picture_attachable_id > 0']
  belongs_to :picture_attachable, :polymorphic => true, :validate => true
  #belongs_to :db_file

  #has_attachment :content_type => :image, #:resize_to => [800,800],
  #  :thumbnails => { :geometry => 'x400' }
  #validates_as_attachment
  has_attached_file :picture, :styles => { :medium => "500x500>", :thumb => "100x100>" }, :path => ":rails_root/private:url"
  validates_attachment_presence :picture
  validates_attachment_content_type :picture, :content_type => %r{image/.*}

  validates_associated :picture_attachable
  validates_presence_of :picture_attachable_id, :picture_attachable_type #, :unless => :parent_id, :on => :create
  default_scope :order => 'position'
  # http://railsforum.com/viewtopic.php?id=11615
  acts_as_list :scope => 'picture_attachable_id=#{picture_attachable_id} AND picture_attachable_type=\'#{picture_attachable_type}\''

  cattr_accessor :per_page
  @@per_page = 10

  def before_save
    picture_attachable_id_string = picture_attachable_id.to_s + picture_attachable_type.to_s
  end

  def after_create
    send_later(:set_digest) if self.picture.path
  end

  def set_digest(options = {:type => 'sha1'})
    file_hash = Digest::SHA1.hexdigest(File.open(self.picture.path, 'rb').read)
    save(false)
  end

  def extname
    File.extname(picture_file_name).gsub(/^\./, '') rescue nil
  end
end
