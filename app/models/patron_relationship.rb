# == Schema Information
#
# Table name: patron_relationships
#
#  id                          :integer          not null, primary key
#  parent_id                   :integer
#  child_id                    :integer
#  patron_relationship_type_id :integer
#  position                    :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#

class PatronRelationship < ActiveRecord::Base
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Patron'
  belongs_to :child, :foreign_key => 'child_id', :class_name => 'Patron'
  belongs_to :patron_relationship_type
  validate :check_parent

  def check_parent
    errors.add(:parent) if parent_id == child_id
  end
end
