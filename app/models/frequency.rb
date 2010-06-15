class Frequency < ActiveRecord::Base
  include MasterModel
  default_scope :order => "position"
  has_many :manifestations
  validates_presence_of :name, :display_name
  validates_uniqueness_of :name
  before_validation :set_display_name, :on => :create

  acts_as_list

  def after_save
    Rails.cache.delete('Frequency.all')
  end

  def after_destroy
    after_save
  end
end
