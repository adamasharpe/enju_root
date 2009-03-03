class Checkin < ActiveRecord::Base
  include LibrarianRequired
  has_one :checkout
  belongs_to :item #, :validate => true
  belongs_to :librarian, :class_name => 'User' #, :validate => true
  belongs_to :basket #, :validate => true

  validates_presence_of :item, :basket
  validates_associated :item, :librarian, :basket

  attr_accessor :item_identifier

  #def other_library_resource?(checkout, library)
  #  return true if library == checkout.item.shelf.library
  #  false
  #end

end
