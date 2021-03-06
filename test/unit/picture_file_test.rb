# == Schema Information
#
# Table name: picture_files
#
#  id                      :integer          not null, primary key
#  picture_attachable_id   :integer
#  picture_attachable_type :string(255)
#  size                    :integer
#  content_type            :string(255)
#  title                   :text
#  filename                :text
#  height                  :integer
#  width                   :integer
#  thumbnail               :string(255)
#  file_hash               :string(255)
#  position                :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  picture_file_name       :string(255)
#  picture_content_type    :string(255)
#  picture_file_size       :integer
#  picture_updated_at      :datetime
#  picture_fingerprint     :string(255)
#

require 'test_helper'

class PictureFileTest < ActiveSupport::TestCase
  fixtures :picture_files

  # Replace this with your real tests.
end
