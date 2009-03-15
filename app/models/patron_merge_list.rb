class PatronMergeList < ActiveRecord::Base
  include LibrarianRequired
  has_many :patron_merges, :dependent => :destroy
  has_many :patrons, :through => :patron_merges
  validates_presence_of :title

  cattr_accessor :per_page
  @@per_page = 10

  def merge_patrons(selected_patron)
    self.patrons.each do |patron|
      Create.update_all(['patron_id = ?', selected_patron.id], ['patron_id = ?', patron.id])
      Realize.update_all(['patron_id = ?', selected_patron.id], ['patron_id = ?', patron.id])
      Produce.update_all(['patron_id = ?', selected_patron.id], ['patron_id = ?', patron.id])
      Own.update_all(['patron_id = ?', selected_patron.id], ['patron_id = ?', patron.id])
      Donate.update_all(['patron_id = ?', selected_patron.id], ['patron_id = ?', patron.id])
      patron.destroy unless patron == selected_patron
    end
  end
end
