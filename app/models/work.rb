class Work < ActiveRecord::Base
  has_many :creates, :dependent => :destroy, :order => :position
  has_many :patrons, :through => :creates, :conditions => 'patrons.deleted_at IS NULL', :order => 'creates.position'
  has_many :reifies, :dependent => :destroy, :order => :position
  has_many :expressions, :through => :reifies, :conditions => 'expressions.deleted_at IS NULL', :include => :expression_form
  belongs_to :work_form #, :validate => true
  has_many :work_merges, :dependent => :destroy
  has_many :work_merge_lists, :through => :work_merges
  has_many :resource_has_subjects, :as => :subjectable, :dependent => :destroy
  has_many :subjects, :through => :resource_has_subjects
  belongs_to :access_role, :class_name => 'Role', :foreign_key => 'access_role_id', :validate => true

  @@per_page = 10
  cattr_reader :per_page

  acts_as_solr :fields => [:title, :context, :note, {:created_at => :date}, {:updated_at => :date}, {:patron_ids => :integer}, {:parent_id => :integer}, {:access_role_id => :range_integer}, {:work_merge_list_ids => :integer}],
    :facets => [:work_form_id], 
    :if => proc{|work| work.deleted_at.blank?}, :auto_commit => false
  acts_as_paranoid
  acts_as_tree

  validates_associated :work_form
  validates_presence_of :original_title, :work_form

  def title
    array = self.titles
    self.expressions.each do |expression|
      array << expression.titles
      expression.manifestations.each do |manifestation|
        array << manifestation.titles
      end
    end
    array.flatten.compact
  end

  def titles
    title = []
    title << original_title
    title << title_transcription
    title << title_alternative
    title << original_title.wakati
    title << title_transcription.wakati rescue nil
    title << title_alternative.wakati rescue nil
    title
  end
  
  def manifestations
    manifestations = []
    expressions.each do |e|
      unless e.serial?
        manifestations << e.manifestations
      end
    end
    manifestations.flatten.uniq
  rescue
    []
  end

  def serials
    self.expressions.find(:all, :conditions => ['frequency_of_issue_id > 1'])
  end

  def expressions_except_serials
    self.expressions - self.serials
  end

  def patron_ids
    self.patrons.collect(&:id)
  end

  def work_merge_lists_ids
    self.work_merge_lists.collect(&:id)
  end

end
