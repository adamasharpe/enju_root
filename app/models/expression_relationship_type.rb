class ExpressionRelationshipType < ActiveRecord::Base
  include OnlyAdministratorCanModify
  default_scope :order => 'position'
  has_many :expression_has_expressions
  validates_presence_of :name, :display_name
  validates_uniqueness_of :name
  acts_as_list
end
