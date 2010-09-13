# -*- encoding: utf-8 -*-
class Patron < ActiveRecord::Base
  include EnjuFragmentCache

  belongs_to :user #, :validate => true
  has_one :library
  has_many :creates, :dependent => :destroy
  has_many :works, :through => :creates, :as => :creators
  has_many :realizes, :dependent => :destroy
  has_many :expressions, :through => :realizes
  has_many :produces, :dependent => :destroy
  has_many :manifestations, :through => :produces
  has_many :owns, :dependent => :destroy
  has_many :items, :through => :owns
  #has_one :person
  #has_one :corporate_body
  #has_one :conference
  has_many :donates
  has_many :donated_items, :through => :donates, :source => :item
  belongs_to :language #, :validate => true
  belongs_to :country #, :validate => true
  has_many :patron_merges, :dependent => :destroy
  has_many :patron_merge_lists, :through => :patron_merges
  #has_many :work_has_subjects, :as => :subjectable, :dependent => :destroy
  #has_many :subjects, :through => :work_has_subjects
  has_many :picture_files, :as => :picture_attachable, :dependent => :destroy
  belongs_to :patron_type #, :validate => true
  belongs_to :required_role, :class_name => 'Role', :foreign_key => 'required_role_id', :validate => true
  has_many :advertises, :dependent => :destroy
  has_many :advertisements, :through => :advertises
  has_many :participates, :dependent => :destroy
  has_many :events, :through => :participates
  #has_many :works_as_subjects, :through => :work_has_subjects, :as => :subjects
  has_many :children, :foreign_key => 'parent_id', :class_name => 'PatronRelationship', :dependent => :destroy
  has_many :parents, :foreign_key => 'child_id', :class_name => 'PatronRelationship', :dependent => :destroy
  has_many :derived_patrons, :through => :children, :source => :child
  has_many :original_patrons, :through => :parents, :source => :parent

  validates_presence_of :full_name, :language, :patron_type, :country
  validates_associated :language, :patron_type, :country
  validates_length_of :full_name, :maximum => 255
  before_validation :set_role_and_name, :on => :create

  searchable do
    text :name, :place, :address_1, :address_2, :other_designation, :note
    string :zip_code_1
    string :zip_code_2
    string :username do
      user.username if user
    end
    time :created_at
    time :updated_at
    time :date_of_birth
    time :date_of_death
    string :user
    integer :work_ids, :multiple => true
    integer :expression_ids, :multiple => true
    integer :manifestation_ids, :multiple => true
    integer :patron_merge_list_ids, :multiple => true
    integer :original_patron_ids, :multiple => true
    integer :required_role_id
    integer :patron_type_id
  end

  #acts_as_soft_deletable
  #acts_as_tree
  has_paper_trail

  attr_accessor :user_username
  def self.per_page
    10
  end

  def set_role_and_name
    self.required_role = Role.first(:conditions => {:name => 'Librarian'}) if self.required_role_id.nil?
    set_full_name
  end

  def set_full_name
    if self.full_name.blank?
      if self.last_name.to_s.strip and self.first_name.to_s.strip and configatron.family_name_first == true
        self.full_name = [last_name, middle_name, first_name].split(", ").to_s.strip
      else
        self.full_name = [first_name, middle_name, middle_name].split(" ").to_s.strip
      end
    end
    if self.full_name_transcription.blank?
      self.full_name_transcription = [last_name_transcription, middle_name_transcription, first_name_transcription].split(" ").to_s.strip
    end
    [self.full_name, self.full_name_transcription]
  end

  #def full_name_generate
  #  # TODO: 日本人以外は？
  #  name = []
  #  name << self.last_name.to_s.strip
  #  name << self.middle_name.to_s.strip unless self.middle_name.blank?
  #  name << self.first_name.to_s.strip
  #  name << self.corporate_name.to_s.strip
  #  name.join(" ").strip
  #end

  def full_name_without_space
    full_name.gsub(/\s/, "")
  #  # TODO: 日本人以外は？
  #  name = []
  #  name << self.last_name.to_s.strip
  #  name << self.middle_name.to_s.strip
  #  name << self.first_name.to_s.strip
  #  name << self.corporate_name.to_s.strip
  #  name.join("").strip
  end

  def full_name_transcription_without_space
    full_name_transcription.to_s.gsub(/\s/, "")
  end

  def full_name_alternative_without_space
    full_name_alternative.to_s.gsub(/\s/, "")
  end

  def name
    name = []
    name << full_name.to_s.strip
    name << full_name_transcription.to_s.strip
    name << full_name_alternative.to_s.strip
    #name << full_name_without_space
    #name << full_name_transcription_without_space
    #name << full_name_alternative_without_space
    #name << full_name.wakati rescue nil
    #name << full_name_transcription.wakati rescue nil
    #name << full_name_alternative.wakati rescue nil
    name
  end

  def date
    if date_of_birth
      if date_of_death
        "#{date_of_birth} - #{date_of_death}"
      else
        "#{date_of_birth} -"
      end
    end
  end

  def author?(expression)
    expression.patrons.each do |patron|
      if self == patron
        return true
      end
    end
    return nil
  end

  def publisher?(manifestation)
    manifestation.patrons.each do |patron|
      if self == patron
        return true
      end
    end
    return nil
  end

  def involved_manifestations
    involvements = []
    works.each do |work|
      involvements << work.manifestations
    end
    expressions.each do |expression|
      involvements << expression.manifestations
    end
    involvements << manifestations
    involvements.flatten.uniq
  end

  #def hidden_patron?
  #  return true if self.required_role.name == 'Librarian'
  #  return true if self.hidden
  #  false
  #end

  def check_required_role(user)
    return true if self.user.blank?
    return true if self.user.required_role.name == 'Guest'
    return true if user == self.user
    return true if user.has_role?(self.user.required_role.name)
    false
  rescue NoMethodError
    false
  end

  def created(work)
    creates.first(:conditions => {:work_id => work.id})
  end

  def realized(expression)
    realizes.first(:conditions => {:expression_id => expression.id})
  end

  def produced(manifestation)
    produces.first(:conditions => {:manifestation_id => manifestation.id})
  end

  def owned(item)
    owns.first(:conditions => {:item_id => item.id})
  end

  def is_readable_by(user, parent = nil)
    true if self.required_role.id == 1 || user.role.id == self.required_role.id || user == self.user
  rescue NoMethodError
    false
  end

  def self.import_patrons(patron_lists)
    patrons = []
    patron_lists.each do |patron_list|
      unless patron = Patron.first(:conditions => {:full_name => patron_list})
        patron = Patron.new(:full_name => patron_list, :language_id => 1)
        patron.required_role = Role.first(:conditions => {:name => 'Guest'})
        patron.save
      end
      patrons << patron
    end
    return patrons
  end

  def patrons
    self.original_patrons + self.derived_patrons
  end

end
