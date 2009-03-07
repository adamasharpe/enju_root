class Realize < ActiveRecord::Base
  include OnlyLibrarianCanModify
  belongs_to :expression, :counter_cache => true #, :validate => true
  belongs_to :patron, :counter_cache => true #, :polymorphic => true, :validate => true

  validates_associated :expression, :patron
  validates_presence_of :expression, :patron
  validates_uniqueness_of :expression_id, :scope => :patron_id
  
  cattr_reader :per_page
  @@per_page = 10
  
  acts_as_list :scope => :expression

end
