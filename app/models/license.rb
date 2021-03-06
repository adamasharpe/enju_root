# == Schema Information
#
# Table name: licenses
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  display_name :string(255)
#  note         :text
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class License < ActiveRecord::Base
  include MasterModel
  default_scope :order => 'position'
end
