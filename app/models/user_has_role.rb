# == Schema Information
#
# Table name: user_has_roles
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  role_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class UserHasRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role

  validates_uniqueness_of :role_id, :scope => :user_id
end
