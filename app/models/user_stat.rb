class UserStat < ActiveRecord::Base
  include AASM
  has_many :user_stat_has_checkouts
  has_many :users, :through => :user_stat_has_checkouts

  aasm_initial_state :pending
  aasm_column :state

  @@per_page = 10
  cattr_reader :per_page

  def culculate_user_checkouts_count
    User.find(:all, :select => :id).each do |user|
      daily_count = Checkout.users_count(self.from_date, self.to_date, user)
      if daily_count > 0
        self.users << user
        UserStat.find_by_sql(['UPDATE user_stat_has_checkouts SET checkouts_count = ? WHERE user_stat_id = ? AND user_id = ?', daily_count, self.id, user.id])
      end
    end
  end
end
