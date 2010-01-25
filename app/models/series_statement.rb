class SeriesStatement < ActiveRecord::Base
  include LibrarianRequired
  has_many :manifestations
  validates_presence_of :title
  acts_as_list
  attr_accessor :manifestation_id

  searchable do
    text :title, :numbering, :title_subseries, :numbering_subseries
    integer :manifestation_ids, :multiple => true
  end

  def last_issue
    manifestations.first(:conditions => 'date_of_publication IS NOT NULL', :order => 'date_of_publication DESC')
  end

end
