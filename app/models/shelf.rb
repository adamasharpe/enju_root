# == Schema Information
#
# Table name: shelves
#
#  id           :integer          not null, primary key
#  name         :string(255)      not null
#  display_name :text
#  note         :text
#  library_id   :integer          default(1), not null
#  items_count  :integer          default(0), not null
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  deleted_at   :datetime
#

class Shelf < ActiveRecord::Base
  include MasterModel
  default_scope :order => "position"
  scope :real, :conditions => ['library_id != 1']
  belongs_to :library, :validate => true
  has_many :items, :include => [:use_restrictions]
  has_many :picture_files, :as => :picture_attachable, :dependent => :destroy
  #has_many :shelf_has_manifestations, :dependent => :destroy
  #has_many :manifestations, :through => :shelf_has_manifestations
  #has_one :user_has_shelf, :dependent => :destroy
  #has_one :user, :through => :user_has_shelf

  validates_associated :library
  validates_presence_of :library
  validates_uniqueness_of :display_name
  
  acts_as_list :scope => :library
  #acts_as_soft_deletable

  paginates_per 10

  def web_shelf?
    return true if self.id == 1
    false
  end

  def self.web
    Shelf.find(1)
  end

  def first?
    # 必ずposition順に並んでいる
    return true if library.shelves.first.position == position
    false
  end

  def localized_display_name
    display_name.localize
  end

end
