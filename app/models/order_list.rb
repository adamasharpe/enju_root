class OrderList < ActiveRecord::Base
  include AASM
  named_scope :not_ordered, :conditions => ['ordered_at IS NULL']

  has_many :orders, :dependent => :destroy
  has_many :purchase_requests, :through => :orders
  belongs_to :user, :validate => true
  belongs_to :bookstore, :validate => true
  has_many :subscriptions

  validates_presence_of :title, :user, :bookstore
  validates_associated :user, :bookstore

  acts_as_soft_deletable

  cattr_reader :per_page
  @@per_page = 10

  aasm_initial_state :pending

  aasm_column :state
  aasm_state :pending
  aasm_state :ordered

  aasm_event :aasm_order do
    transitions :from => :pending, :to => :ordered,
      :on_transition => :order
  end

  def total_price
    self.purchase_requests.sum(:price)
  end

  def order
  end
end
