class WorkMergeList < ActiveRecord::Base
  include LibrarianRequired
  has_many :work_merges, :dependent => :destroy
  has_many :works, :through => :work_merges
  validates_presence_of :title

  cattr_reader :per_page
  @@per_page = 10

  def merge_works(selected_work)
    self.works.each do |work|
      Create.update_all(['work_id = ?', selected_work.id], ['work_id = ?', work.id])
      Reify.update_all(['work_id = ?', selected_work.id], ['work_id = ?', work.id])
      work.destroy unless work == selected_work
    end
  end
end
