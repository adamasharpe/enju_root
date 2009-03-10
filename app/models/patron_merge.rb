class PatronMerge < ActiveRecord::Base
  include LibrarianRequired
  belongs_to :patron, :validate => true
  belongs_to :patron_merge_list, :validate => true
  validates_presence_of :patron, :patron_merge_list
  validates_associated :patron, :patron_merge_list

  cattr_reader :per_page
  @@per_page = 10
end
