class Subscribe < ActiveRecord::Base
  belongs_to :subscription, :counter_cache => true, :validate => true
  belongs_to :work, :validate => true

  validates_associated :subscription, :work
  validates_presence_of :subscription, :work, :start_at, :end_at
  validates_uniqueness_of :work_id, :scope => :subscription_id
end
