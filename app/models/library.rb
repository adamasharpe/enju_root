# -*- encoding: utf-8 -*-
require 'mathn'
class Library < ActiveRecord::Base
  default_scope :order => 'libraries.position'
  named_scope :real, :conditions => ['id != 1']
  has_many :shelves, :order => 'shelves.position'
  belongs_to :library_group, :validate => true
  has_many :events, :include => :event_category
  #belongs_to :holding_patron, :polymorphic => true, :validate => true
  belongs_to :patron, :validate => true
  has_many :inter_library_loans, :foreign_key => 'borrowing_library_id'
  has_many :users
  belongs_to :country

  acts_as_list
  #acts_as_soft_deletable
  has_friendly_id :name
  #acts_as_geocodable
  geocoded_by :address
  enju_calil_library

  searchable do
    text :name, :display_name, :note, :address
    time :created_at
    time :updated_at
  end

  #validates_associated :library_group, :holding_patron
  validates_associated :library_group, :patron
  validates_presence_of :name, :display_name, :short_display_name, :library_group, :patron
  validates_uniqueness_of :name, :short_display_name, :case_sensitive => false
  validates_uniqueness_of :display_name
  validates_format_of :name, :with => /^[a-z][0-9a-z]{2,254}$/

  def self.per_page
    10
  end

  def after_save
    expire_cache
  end

  after_validation :fetch_coordinates

  def before_save
    set_calil_neighborhood_library
    #set_geocode
  end

  def set_geocode
    self.latitude = self.geocode.latitude
    self.longitude = self.geocode.longitude
  rescue NoMethodError
    nil
  end

  def set_calil_neighborhood_library
    self.calil_neighborhood_systemid = self.calil_library(self.access_calil).collect{|l| l[:systemid]}.uniq.join(',')
  end

  def after_destroy
    after_save
  end

  def expire_cache
    Rails.cache.delete("Library:#{id}")
    Rails.cache.delete('Library.all')
  end

  def before_validation
    self.display_name = self.name if display_name.blank?
  end

  def closed?(date)
    events.closing_days.collect{|c| c.start_at.beginning_of_day}.include?(date.beginning_of_day)
  end

  def web?
    return true if self.id == 1
    false
  end

  def self.web
    Rails.cache.fetch("Library:1"){Library.find(1)}
  end

  def address
    self.region.to_s + self.locality.to_s + " " + self.street.to_s
  rescue
    nil
  end

end
