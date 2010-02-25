# -*- encoding: utf-8 -*-
class UserGroup < ActiveRecord::Base
  include OnlyAdministratorCanModify

  default_scope :order => "position"
  has_many :users
  #has_many :available_carrier_types
  #has_many :carrier_types, :through => :available_carrier_types, :order => :position
  has_many :user_group_has_checkout_types, :dependent => :destroy
  has_many :checkout_types, :through => :user_group_has_checkout_types, :order => :position
  has_many :lending_policies

  validates_presence_of :name, :display_name
  validates_uniqueness_of :name, :case_sensitive => false
  validates_uniqueness_of :display_name

  acts_as_list

  def self.per_page
    10
  end

  def before_validation_on_create
    self.display_name = self.name if display_name.blank?
  end

  def after_save
    Rails.cache.delete('UserGroup.all')
  end

  def after_destroy
    after_save
  end
end
