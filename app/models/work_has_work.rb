class WorkHasWork < ActiveRecord::Base
  include OnlyLibrarianCanModify
  belongs_to :from_work, :foreign_key => 'from_work_id', :class_name => 'Work'
  belongs_to :to_work, :foreign_key => 'to_work_id', :class_name => 'Work'
  belongs_to :work_relationship_type

  validates_presence_of :from_work, :to_work, :work_relationship_type
  validates_uniqueness_of :from_work_id, :scope => :to_work_id

  acts_as_list :scope => :from_work
end
