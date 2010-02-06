# -*- encoding: utf-8 -*-
class Answer < ActiveRecord::Base
  include LibrarianOwnerRequired
  named_scope :public_answers, :conditions => {:shared => true}
  named_scope :private_answers, :conditions => {:shared => false}
  belongs_to :user, :counter_cache => true, :validate => true
  belongs_to :question, :counter_cache => true, :validate => true

  #acts_as_soft_deletable
  after_save :save_questions

  validates_associated :user, :question
  validates_presence_of :user_id, :question_id, :body

  cattr_accessor :per_page
  @@per_page = 10

  def save_questions
    self.question.save
  end

  def self.is_indexable_by(user, parent = nil)
  #  if user.try(:has_role?, 'User')
      true
  #  else
  #    false
  #  end
  end

  def is_readable_by(user, parent = nil)
    true if user == self.user || self.shared? || user.has_role?('Librarian')
  rescue
    false
  end

end
