class Subscription < ActiveRecord::Base
  has_many :subscribes, :dependent => :destroy
  has_many :works, :through => :subscribes
  belongs_to :user, :validate => true
  belongs_to :order_list, :validate => true

  validates_presence_of :title, :user
  validates_associated :user

  searchable do
    text :title, :note
    time :created_at
    time :updated_at
    integer :work_ids, :multiple => true
  end
  #acts_as_soft_deletable

  def self.per_page
    10
  end

  def subscribed(work)
    subscribes.where(:work_id => work.id).first
  end

end
# == Schema Information
#
# Table name: subscriptions
#
#  id               :integer         not null, primary key
#  title            :text            not null
#  note             :text
#  user_id          :integer
#  order_list_id    :integer
#  deleted_at       :datetime
#  subscribes_count :integer         default(0), not null
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#

