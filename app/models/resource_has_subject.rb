class ResourceHasSubject < ActiveRecord::Base
  #belongs_to :subject, :counter_cache => true, :validate => true
  #belongs_to :subjectable, :polymorphic => true, :counter_cache => true, :validate => true
  belongs_to :work #, :counter_cache => true, :validate => true
  belongs_to :subject, :polymorphic => true #, :counter_cache => true, :validate => true

  validates_presence_of :work_id, :subject_id, :subject_type
  validates_associated :work, :subject
  #validates_presence_of :subject_id, :subjectable_id, :subjectable_type
  #validates_associated :subject, :subjectable
  validates_uniqueness_of [:subject_id, :subject_type], :scope => :work_id

  cattr_reader :per_page
  @@per_page = 10

  #def after_save
  #  self.subject.save
  #  self.subjectable.save
  #end
end
