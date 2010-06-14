class RequestStatusType < ActiveRecord::Base
  include MasterModel
  has_many :reserves
  validates_presence_of :name, :display_name
  validates_uniqueness_of :name
  before_validation :set_display_name, :on => :create

  acts_as_list
end
