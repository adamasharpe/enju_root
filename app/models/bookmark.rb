class Bookmark < ActiveRecord::Base
  named_scope :bookmarked, lambda {|from_date, to_date| {:conditions => ['created_at >= ? AND created_at < ?', from_date, to_date]}}
  belongs_to :bookmarked_resource, :counter_cache => true #, :validate => true
  belongs_to :user #, :counter_cache => true, :validate => true
  validates_presence_of :user, :bookmarked_resource_id, :title
  validates_presence_of :url, :on => :create
  validates_associated :user, :bookmarked_resource
  validates_uniqueness_of :bookmarked_resource_id, :scope => :user_id
  validates_length_of :url, :maximum => 255, :allow_nil => true
  
  cattr_reader :per_page
  attr_accessor :url
  attr_accessor :title
  @@per_page = 10

  acts_as_taggable

  def after_save
    if self.bookmarked_resource
      self.bookmarked_resource.reload
      self.bookmarked_resource.save
    end
  end

  def after_destroy
    after_save
  end

  #def title
  #  self.bookmarked_resource.title
  #end

  def url
    self.bookmarked_resource.url
  end

  def shelved?
    true if self.bookmarked_resource.manifestation.items.find(:first, :select => :id, :include => :shelf, :conditions => ['shelves.id = 1']) rescue nil
  end

  # エンコード済みのURLを渡す
  def self.get_title(url)
    return if url.blank?
    #requested_url = URI.parse(URI.escape(url))
    requested_url = URI.parse(url)
    if requested_url.host == LIBRARY_WEB_HOSTNAME
    # TODO: ホスト名の扱い
      if requested_url.host == 'localhost' and requested_url.port == 3000
        access_url = requested_url.normalize.to_s.gsub('localhost:3000', 'localhost:3001')
      else
        access_url = requested_url.normalize.to_s.gsub("#{LIBRARY_WEB_HOSTNAME}", 'localhost:3001')
      end
    else
      access_url = url
    end

    page = open(access_url)
    doc = Hpricot(page)
    # TODO: 日本語以外
    #charsets = ['iso-2022-jp', 'euc-jp', 'shift_jis', 'iso-8859-1']
    #if charsets.include?(page.charset.downcase)
      title = NKF.nkf('-w', CGI.unescapeHTML((doc/"title").inner_text))
      if title.to_s.strip.blank?
        title = url
      end
    #else
    #  title = (doc/"title").inner_text
    #end
    title
  rescue
    # TODO 404などの場合の処理
    nil
  end

  def create_bookmark_item
    self.reload
    shelf = Shelf.find(1) # ブックマーク用の書棚のIDは常に1
    circulation_status = CirculationStatus.find(:first, :conditions => {:name => 'Not Available'})
    item = Item.new
    item.circulation_status = circulation_status
    item.shelf = shelf
    self.bookmarked_resource.manifestation.items << item
  end

  def self.manifestations_count(from_date, to_date, manifestation)
    self.bookmarked(from_date, to_date).find(:all, :conditions => {:manifestation_id => manifestation.id}).count
  end
end
