class ManifestationCheckoutStat < ActiveRecord::Base
  include AASM
  include OnlyLibrarianCanModify
  has_many :checkout_stat_has_manifestations
  has_many :manifestations, :through => :checkout_stat_has_manifestations

  validates_presence_of :start_date, :end_date

  aasm_initial_state :pending
  aasm_column :state

  @@per_page = 10
  cattr_accessor :per_page

  def validate
    if self.start_date and self.end_date
      if self.start_date >= self.end_date
        errors.add(:start_date)
        errors.add(:end_date)
      end
    end
  end

  def calculate_manifestation_count
    Manifestation.find_each do |manifestation|
      daily_count = Checkout.manifestations_count(self.start_date, self.end_date, manifestation)
      #manifestation.update_attributes({:daily_checkouts_count => daily_count, :total_count => manifestation.total_count + daily_count})
      if daily_count > 0
        self.manifestations << manifestation
        ManifestationCheckoutStat.find_by_sql(['UPDATE checkout_stat_has_manifestations SET checkouts_count = ? WHERE manifestation_checkout_stat_id = ? AND manifestation_id = ?', daily_count, self.id, manifestation.id])
      end
    end
  end
end
