# -*- encoding: utf-8 -*-
require 'timeout'
class Question < ActiveRecord::Base
  include LibrarianOwnerRequired
  default_scope :order => 'id DESC'
  named_scope :public_questions, :conditions => {:shared => true}
  named_scope :private_questions, :conditions => {:shared => false}
  belongs_to :user, :counter_cache => true, :validate => true
  has_many :answers, :dependent => :destroy

  validates_associated :user
  validates_presence_of :user, :body
  #acts_as_soft_deletable
  searchable do
    text :body, :answer_body
    string :login
    time :created_at
    time :updated_at do
      last_updated_at
    end
    boolean :shared
    boolean :solved
    integer :answers_count
  end

  acts_as_taggable_on :tags
  enju_porta
 
  def self.per_page
    10
  end

  def self.crd_per_page
    5
  end

  def answer_body
    text = ""
    self.reload
    self.answers.each do |answer|
      text += answer.body
    end
    return text
  end

  def login
    self.user.login
  end

  def is_readable_by(user, parent = nil)
    return true if user == self.user || self.shared? || user.try(:has_role?, 'Librarian')
    false
  end

  def last_updated_at
    if answers.last
      time = answers.last.updated_at
    end
    if time
      if time > updated_at
        time
      else
        updated_at
      end
    else
      updated_at
    end
  end
end
