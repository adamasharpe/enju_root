# -*- encoding: utf-8 -*-
#require 'wakati'
require 'timeout'
class Manifestation < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  #include OnlyLibrarianCanModify
  include LibrarianOwnerRequired
  include SolrIndex
  #named_scope :pictures, :conditions => {:content_type => ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png']}
  named_scope :pictures, :conditions => {:attachment_content_type => ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png']}
  named_scope :serials, :conditions => ['frequency_id > 1']
  named_scope :not_serials, :conditions => ['frequency_id = 1']
  has_many :embodies, :dependent => :destroy, :order => :position
  has_many :expressions, :through => :embodies, :order => 'embodies.position', :dependent => :destroy
  has_many :exemplifies, :dependent => :destroy
  has_many :items, :through => :exemplifies, :dependent => :destroy
  has_many :produces, :dependent => :destroy
  has_many :patrons, :through => :produces, :order => 'produces.position'
  #has_one :manifestation_api_response, :dependent => :destroy
  has_many :reserves, :dependent => :destroy
  has_many :reserving_users, :through => :reserves, :source => :user
  belongs_to :carrier_type #, :validate => true
  belongs_to :extent #, :validate => true
  belongs_to :language, :validate => true
  has_many :picture_files, :as => :picture_attachable, :dependent => :destroy
  #has_many :orders, :dependent => :destroy
  #has_many :work_has_subjects, :as => :subjectable, :dependent => :destroy
  #has_many :subjects, :through => :work_has_subjects
  belongs_to :required_role, :class_name => 'Role', :foreign_key => 'required_role_id', :validate => true
  has_many :checkout_stat_has_manifestations
  has_many :checkout_stats, :through => :checkout_stat_has_manifestations
  has_many :bookmark_stat_has_manifestations
  has_many :bookmark_stats, :through => :bookmark_stat_has_manifestations
  has_many :reserve_stat_has_manifestations
  has_many :reserve_stats, :through => :reserve_stat_has_manifestations
  has_many :to_manifestations, :foreign_key => 'from_manifestation_id', :class_name => 'ManifestationHasManifestation', :dependent => :destroy
  has_many :from_manifestations, :foreign_key => 'to_manifestation_id', :class_name => 'ManifestationHasManifestation', :dependent => :destroy
  has_many :derived_manifestations, :through => :to_manifestations, :source => :to_manifestation
  has_many :original_manifestations, :through => :from_manifestations, :source => :from_manifestation
  #has_many_polymorphs :patrons, :from => [:people, :corporate_bodies, :families], :through => :produces
  belongs_to :frequency #, :validate => true
  has_many :bookmarks
  has_many :users, :through => :bookmarks
  belongs_to :nii_type
  belongs_to :series_statement
  has_one :import_request

  searchable do
    text :title, :fulltext, :note, :author, :editor, :publisher, :subject
    text :tag do
      tags.collect(&:name)
    end
    string :isbn, :multiple => true do
      [isbn, isbn10, wrong_isbn]
    end
    string :issn
    string :lccn
    string :nbn
    string :tag, :multiple => true do
      tags.collect(&:name)
    end
    string :carrier_type do
      carrier_type.name
    end
    string :library, :multiple => true
    string :language, :multiple => true do
      languages.collect(&:name)
    end
    string :shelf, :multiple => true
    string :user, :multiple => true
    string :subject, :multiple => true
    integer :subject_ids, :multiple => true do
      self.subjects.collect(&:id)
    end
    string :sort_title
    time :created_at
    time :updated_at
    time :date_of_publication
    integer :patron_ids, :multiple => true
    integer :item_ids, :multiple => true
    integer :original_manifestation_ids, :multiple => true
    integer :derived_manifestation_ids, :multiple => true
    integer :expression_ids, :multiple => true
    integer :required_role_id
    integer :carrier_type_id
    integer :height
    integer :width
    integer :depth
    integer :volume_number, :multiple => true
    integer :issue_number, :multiple => true
    integer :serial_number, :multiple => true
    integer :start_page
    integer :end_page
    integer :number_of_pages
    float :price
    boolean :reservable
    integer :series_statement_id
  end

  #acts_as_tree
  enju_twitter
  enju_manifestation_viewer
  enju_amazon
  enju_porta
  enju_cinii
  has_attached_file :attachment
  has_ipaper_and_uses 'Paperclip'
  enju_scribd
  enju_mozshot
  enju_oai_pmh
  #enju_worldcat
  has_paper_trail

  @@per_page = 10
  cattr_accessor :per_page
  attr_accessor :new_expression_id

  validates_presence_of :original_title, :carrier_type_id, :language_id
  validates_associated :carrier_type, :language
  validates_numericality_of :start_page, :end_page, :allow_blank => true
  validates_length_of :access_address, :maximum => 255, :allow_blank => true
  validates_uniqueness_of :isbn, :allow_blank => true
  validates_uniqueness_of :nbn, :allow_blank => true
  validates_format_of :access_address, :with => URI::regexp(%w(http https)) , :allow_blank => true

  def set_wrong_isbn
    #unless self.date_of_publication.blank?
    #  date = Time.parse(self.date_of_publication.to_s) rescue nil
    #  errors.add(:date_of_publication) unless date
    #end

    if isbn.present?
      wrong_isbn = isbn unless ISBN_Tools.is_valid?(isbn)
    end
  end

  def before_validation_on_create
    return nil unless self.isbn
    ISBN_Tools.cleanup!(self.isbn)
    if self.isbn.length == 10
      isbn10 = self.isbn.dup
      self.isbn = ISBN_Tools.isbn10_to_isbn13(self.isbn)
      self.isbn10 = isbn10
    end
    set_wrong_isbn
  rescue NoMethodError
    nil
  end

  def before_validation_on_update
    ISBN_Tools.cleanup!(self.isbn) if self.isbn.present?
  end

  def after_create
    send_later(:set_digest) if self.attachment.path
    Rails.cache.delete("Manifestation.search.total")
    Manifestation.expire_top_page_cache
  end

  def after_save
    send_later(:expire_cache)
    send_later(:generate_fragment_cache)
  end

  def after_destroy
    Rails.cache.delete("Manifestation.search.total")
    send_later(:expire_cache)
    Manifestation.expire_top_page_cache
  end

  def expire_cache
    sleep 3
    Rails.cache.delete("worldcat_record_#{id}")
    Rails.cache.delete("xisbn_manifestations_#{id}")
    Rails.cache.fetch("manifestation_screen_shot_#{id}")
  end

  def self.expire_top_page_cache
    I18n.available_locales.each do |locale|
      Rails.cache.delete("views/#{LIBRARY_WEB_HOSTNAME}/?locale=#{locale}&name=search_form")
    end
  end

  def self.cached_numdocs
    Rails.cache.fetch("Manifestation.search.total"){Manifestation.search.total}
  end

  def full_title
    # TODO: 号数
    original_title + " " + volume_number.to_s
  end

  def title
    array = self.titles
    self.expressions.each do |expression|
      array << expression.titles
      if expression.work
        array << expression.work.title
      end
    end
    #array << worldcat_record[:title] if worldcat_record
    array.flatten.compact.sort.uniq
  end

  def titles
    title = []
    title << original_title
    title << title_transcription
    title << title_alternative
    #title << original_title.wakati
    #title << title_transcription.wakati rescue nil
    #title << title_alternative.wakati rescue nil
    title
  end

  def url
    #access_address
    "#{LibraryGroup.url}manifestations/#{self.id}"
  end

  def available_checkout_types(user)
    user.user_group.user_group_has_checkout_types.available_for_carrier_type(self.carrier_type)
  end

  def checkout_period(user)
    available_checkout_types(user).collect(&:checkout_period).max
  end
  
  def reservation_expired_period(user)
    available_checkout_types(user).collect(&:reservation_expired_period).max
  end
  
  def embodies?(expression)
    expression.manifestations.detect{|manifestation| manifestation == self}
  end

  def serial?
    return true if series_statement
    #return true if parent_of_series
    #return true if frequency_id > 1
    false
  end

  def parent_of_series
    id = self.id
    Work.search do
      with(:manifestation_ids).equal_to id
      with(:parent_of_series).equal_to true
    end.results.first
    # TODO: parent_of_series をシリーズ中にひとつしか作れないようにする
  end

  def create_next_issue_work_and_expression
    return nil unless parent_of_series
    work = Work.create(
      :original_title => parent_of_series.original_title,
      :title_alternative => parent_of_series.title_alternative,
      :title_transcription => parent_of_series.title_transcription,
      :context => parent_of_series.context,
      :form_of_work_id => parent_of_series.form_of_work_id,
      :medium_of_performance_id => parent_of_series.medium_of_performance_id,
      :required_role_id => parent_of_series.required_role_id
    )
    expression = Expression.new(
      :original_title => parent_of_series.original_title,
      :title_alternative => parent_of_series.title_alternative,
      :title_transcription => parent_of_series.title_transcription,
      :language_id => self.language_id
    )
    work.expressions << expression
    work.patrons << parent_of_series.patrons
    self.expressions << expression
  end

  def next_reservation
    self.reserves.first(:order => ['reserves.created_at'])
  end

  def authors
    patron_ids = []
    # 著編者
    (self.works.collect{|w| w.patrons}.flatten + self.expressions.collect{|e| e.patrons}.flatten).uniq
  end

  def editors
    patrons = []
    self.expressions.each do |expression|
      patrons += expression.patrons.uniq
    end
    patrons -= authors
  end

  def publishers
    self.patrons
  end

  def shelves
    self.items.collect{|item| item.shelves}.flatten.uniq
  end

  def tags
    unless self.bookmarks.empty?
      self.bookmarks.collect{|bookmark| bookmark.tags}.flatten.uniq
    else
      []
    end
  end

  def works
    self.expressions.collect{|e| e.work}.uniq.compact
  end

  def patron
    self.patrons.collect(&:name) + self.expressions.collect{|e| e.patrons.collect(&:name) + e.work.patrons.collect(&:name)}.flatten
  end

  def shelf
    self.items.collect{|i| i.shelf.library.name + i.shelf.name}
  end

  def related_manifestations
    # TODO: 定期刊行物をモデルとビューのどちらで抜くか
    manifestations = self.works.collect{|w| w.expressions.collect{|e| e.manifestations}}.flatten.uniq.compact + self.original_manifestations + self.derived_manifestations - Array(self)
  end

  def sort_title
    # 並べ替えの順番に使う項目を指定する
    # TODO: 読みが入力されていない資料
    self.title_transcription
  end

  def subjects
    works.collect(&:subjects).flatten
  end
  
  def library
    library_names = []
    self.items.each do |item|
      library_names << item.shelf.library.name
    end
    library_names.uniq
  end

  def volume_number
    volume_number_list.gsub(/\D/, ' ').split(" ") if volume_number_list
  end

  def issue_number
    issue_number_list.gsub(/\D/, ' ').split(" ") if issue_number_list
  end

  def serial_number
    serial_number_list.gsub(/\D/, ' ').split(" ") if serial_number_list
  end

  def forms
    self.expressions.collect(&:content_type).uniq
  end

  def languages
    self.expressions.collect(&:language).uniq
  end

  def number_of_contents
    self.expressions.size - self.expressions.serials.size
  end

  def number_of_pages
    if self.start_page and self.end_page
      page = self.end_page.to_i - self.start_page.to_i + 1
    end
  end

  def publisher
    publishers.collect(&:name).flatten
  end

  def author
    authors.collect(&:name).flatten
  end

  def editor
    editors.collect(&:name).flatten
  end

  def subject
    subjects.collect(&:term) + subjects.collect(&:term_transcription)
  end

  def isbn13
    isbn
  end

  def self.find_by_isbn(isbn)
    if ISBN_Tools.is_valid?(isbn)
      ISBN_Tools.cleanup!(isbn)
      manifestation = Manifestation.first(:conditions => {:isbn => isbn})
      if manifestation.nil?
        if isbn.length == 13
          isbn = ISBN_Tools.isbn13_to_isbn10(isbn)
        else
          isbn = ISBN_Tools.isbn10_to_isbn13(isbn)
        end
        manifestation = Manifestation.first(:conditions => {:isbn => isbn})
      end
    end
    return manifestation
  rescue NoMethodError
    nil
  end

  def subjects
    self.works.collect(&:subjects).flatten
  end

  def user
    if self.bookmarks
      self.bookmarks.collect(&:user).collect(&:login)
    else
      []
    end
  end

  # TODO: よりよい推薦方法
  def self.pickup(keyword = nil)
    return nil if self.cached_numdocs < 5
    resource = nil
    # TODO: ヒット件数が0件のキーワードがあるときに指摘する
    response = Sunspot.search(Manifestation) do
      fulltext keyword if keyword
      order_by(:random)
      paginate :page => 1, :per_page => 1
    end
    resource = response.results.first
    #if resource.nil?
    #  while resource.nil?
    #    resource = self.find(rand(self.cached_numdocs) + 1) rescue nil
    #  end
    #end
    #return resource
  end

  def self.import_patrons(patron_lists)
    patrons = []
    patron_lists.each do |patron_list|
      unless patron = Patron.first(:conditions => {:full_name => patron_list})
        patron = Patron.new(:full_name => patron_list, :language_id => 1)
        patron.required_role = Role.first(:conditions => {:name => 'Guest'})
      end
      patron.save
      patrons << patron
    end
    return patrons
  end

  def set_serial_number
    if m = series_statement.try(:last_issue)
      self.original_title = m.original_title
      self.title_transcription = m.title_transcription
      self.title_alternative = m.title_alternative
      self.issn = m.issn
      unless m.serial_number_list.blank?
        self.serial_number_list = m.serial_number_list.to_i + 1
        unless m.issue_number_list.blank?
          self.issue_number_list = m.issue_number_list.split.last.to_i + 1
        else
          self.issue_number_list = m.issue_number_list
        end
        self.volume_number_list = m.volume_number_list
      else
        unless m.issue_number_list.blank?
          self.issue_number_list = m.issue_number_list.split.last.to_i + 1
          self.volume_number_list = m.volume_number_list
        else
          unless m.volume_number_list.blank?
            self.volume_number_list = m.volume_number_list.split.last.to_i + 1
          end
        end
      end
    end
    return self
  end

  def is_reserved_by(user = nil)
    if user
      return true if Reserve.waiting.first(:conditions => {:user_id => user.id, :manifestation_id => self.id})
    else
      return true if self.reserves.present?
    end
    false
  end

  def reservable
    return false if self.items.not_for_checkout.present?
    true
  end

  def checkouts(start_date, end_date)
    Checkout.completed(start_date, end_date).all(:conditions => {:item_id => self.items.collect(&:id)})
  end

  #def bookmarks(start_date = nil, end_date = nil)
  #  if start_date.blank? and end_date.blank?
  #    if self.bookmarks
  #      self.bookmarks
  #    else
  #      []
  #    end
  #  else
  #    Bookmark.bookmarked(start_date, end_date).find(:all, :conditions => {:manifestation_id => self.id})
  #  end
  #end

  def set_digest(options = {:type => 'sha1'})
    file_hash = Digest::SHA1.hexdigest(File.open(self.attachment.path, 'rb').read)
    save(false)
  end

  def generate_fragment_cache
    sleep 3
    url = "#{LibraryGroup.url}manifestations/#{id}?mode=generate_cache"
    Net::HTTP.get(URI.parse(url))
  end

  def extract_text
    extractor = ExtractContent::Extractor.new
    text = Tempfile::new("text")
    case self.attachment_content_type
    when "application/pdf"
      system("pdftotext -q -enc UTF-8 -raw #{attachment(:path)} #{text.path}")
      self.fulltext = text.read
    when "application/msword"
      system("antiword #{attachment(:path)} 2> /dev/null > #{text.path}")
      self.fulltext = text.read
    when "application/vnd.ms-excel"
      system("xlhtml #{attachment(:path)} 2> /dev/null > #{text.path}")
      self.fulltext = extractor.analyse(text.read)
    when "application/vnd.ms-powerpoint"
      system("ppthtml #{attachment(:path)} 2> /dev/null > #{text.path}")
      self.fulltext = extractor.analyse(text.read)
    when "text/html"
      # TODO: 日本語以外
      system("elinks --dump 1 #{attachment(:path)} 2> /dev/null | nkf -w > #{text.path}")
      self.fulltext = extractor.analyse(text.read)
    end

    #self.indexed_at = Time.zone.now
    self.save(false)
    text.close
  end

  def derived_manifestations_by_solr(options = {})
    page = options[:page] || 1
    sort_by = options[:sort_by] || 'created_at'
    order = options[:order] || 'desc'
    manifestation_id = id
    search = Sunspot.new_search(Manifestation)
    search.build do
      with(:original_manifestation_ids).equal_to manifestation_id
      order_by(sort_by, order)
    end
    search.query.paginate page.to_i, Manifestation.per_page
    search.execute!.results
  end

  def bookmarked?(user)
    self.users.include?(user)
  end

  def bookmarks_count
    self.bookmarks.size
  end

  def produced(patron)
    produces.first(:conditions => {:patron_id => patron.id})
  end

  def embodied(expression)
    embodies.first(:conditions => {:expression_id => expression.id})
  end

end
