# == Schema Information
#
# Table name: extents
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  display_name :text
#  note         :text
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'test_helper'

class ExtentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
