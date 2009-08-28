class WorkRelationshipType < ActiveRecord::Base
  include OnlyAdministratorCanModify
  has_many :work_has_works
  validates_presence_of :name, :display_name
  validates_uniqueness_of :name
  acts_as_list
end
