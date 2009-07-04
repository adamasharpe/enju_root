class Advertisement < ActiveRecord::Base
  include AdministratorRequired
  named_scope :current_ads, :conditions => ['started_at <= ? AND ended_at > ?', Time.zone.now, Time.zone.now], :order => :id
  named_scope :previous_ads, :conditions => ['ended_at <= ?', Time.zone.now], :order => :id

  has_many :advertises, :dependent => :destroy
  has_many :patrons, :through => :advertises
  #has_many_polymorphs :patrons, :from => [:people, :corporate_bodies, :families], :through => :advertises

  validates_presence_of :title, :body, :started_at, :ended_at
  validates_length_of :url, :maximum => 255, :allow_blank => true

  acts_as_solr :fields => [:title, :body, {:url => :string}, :note, {:created_at => :date}, {:updated_at => :date}, {:started_at => :date}, {:ended_at => :date}], :auto_commit => false
  #acts_as_soft_deletable

  @@per_page = 10
  cattr_accessor :per_page

  def validate
    if self.started_at and self.ended_at
      if self.started_at > self.ended_at
        errors.add(:started_at)
        errors.add(:ended_at)
      end
    end
  end

  def after_save
    Advertisement.expire_cache
  end

  def self.cached_current_ads
    Rails.cache.fetch('Advertisement.current_ads'){Advertisement.current_ads}
  end

  def self.expire_cache
    Rails.cache.delete('Advertisement.current_ads')
  end

  def self.pickup
    ids = Advertisement.cached_current_ads.collect(&:id)
    id = ids.at(rand(ids.size))
    advertisement = Advertisement.find(id)
  end
end
