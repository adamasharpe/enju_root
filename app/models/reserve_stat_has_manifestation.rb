class ReserveStatHasManifestation < ActiveRecord::Base
  belongs_to :manifestation_reserve_stat
  belongs_to :manifestation

  validates_uniqueness_of :manifestation_id, :scope => :manifestation_reserve_stat_id

  @@per_page = 10
  cattr_reader :per_page
end
