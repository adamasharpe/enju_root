class UserCheckoutStatHasUser < ActiveRecord::Base
  belongs_to :user_checkout_stat
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :user_checkout_stat_id
end
