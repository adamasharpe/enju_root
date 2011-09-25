class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :lockable and :timeoutable
  devise :database_authenticatable, #:registerable, :confirmable,
         :recoverable, :rememberable, :trackable, #:validatable,
         :lockable, :lock_strategy => :none, :unlock_strategy => :none

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :username, :current_password, :user_number, :remember_me

  scope :administrators, :include => ['role'], :conditions => ['roles.name = ?', 'Administrator']
  scope :librarians, :include => ['role'], :conditions => ['roles.name = ? OR roles.name = ?', 'Administrator', 'Librarian']
  scope :suspended, :conditions => ['locked_at IS NOT NULL']
  has_one :patron
  has_many :import_requests
  has_many :sent_messages, :foreign_key => 'sender_id', :class_name => 'Message'
  has_many :received_messages, :foreign_key => 'receiver_id', :class_name => 'Message'
  has_many :picture_files, :as => :picture_attachable, :dependent => :destroy
  has_many :import_requests
  has_one :user_has_role
  has_one :role, :through => :user_has_role
  has_many :bookmarks, :dependent => :destroy
  has_many :questions
  has_many :answers
  has_many :search_histories, :dependent => :destroy
  has_many :subscriptions
  belongs_to :library, :validate => true
  belongs_to :user_group
  belongs_to :required_role, :class_name => 'Role', :foreign_key => 'required_role_id' #, :validate => true
  has_one :patron_import_result

  validates :username, :presence => true, :uniqueness => true
  validates_uniqueness_of :email, :scope => authentication_keys[1..-1], :case_sensitive => false, :allow_blank => true
  validates :email, :format => {:with => /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i}, :allow_blank => true
  validates_date :expired_at, :allow_blank => true

  with_options :if => :password_required? do |v|
    v.validates_presence_of     :password
    v.validates_confirmation_of :password
    v.validates_length_of       :password, :within => 6..20, :allow_blank => true
  end

  validates_presence_of     :email, :email_confirmation, :on => :create, :if => proc{|user| !user.operator.try(:has_role?, 'Librarian')}
  validates_associated :patron, :user_group, :library
  validates_presence_of :user_group, :library, :locale #, :user_number
  validates :user_number, :uniqueness => true, :format => {:with => /\A[0-9A-Za-z_]+\Z/}, :allow_blank => true
  validates_confirmation_of :email, :email_confirmation, :on => :create, :if => proc{|user| !user.operator.try(:has_role?, 'Librarian')}
  before_validation :set_role_and_patron, :on => :create
  before_validation :set_lock_information
  before_save :check_expiration
  before_create :set_expired_at
  after_destroy :remove_from_index
  after_create :set_confirmation
  after_save :index_patron
  after_destroy :index_patron

  extend FriendlyId
  friendly_id :username
  #acts_as_tagger
  has_paper_trail
  normalize_attributes :username, :user_number #, :email

  searchable do
    text :username, :email, :note, :user_number
    text :name do
      patron.name if patron
    end
    string :username
    string :email
    string :user_number
    integer :required_role_id
    time :created_at
    time :updated_at
    boolean :active do
      active_for_authentication?
    end
    time :confirmed_at
  end

  attr_accessor :first_name, :middle_name, :last_name, :full_name,
    :first_name_transcription, :middle_name_transcription,
    :last_name_transcription, :full_name_transcription,
    :zip_code, :address, :telephone_number, :fax_number, :address_note,
    :role_id, :patron_id, :operator, :password_not_verified,
    :update_own_account, :auto_generated_password, :current_password,
    :locked

  def self.per_page
    10
  end
  
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def has_role?(role_in_question)
    return false unless role
    return true if role.name == role_in_question
    case role.name
    when 'Administrator'
      return true
    when 'Librarian'
      return true if role_in_question == 'User'
    else
      false
    end
  end

  def set_role_and_patron
    self.required_role = Role.find_by_name('Librarian')
    self.locale = I18n.default_locale.to_s
    unless self.patron
      self.patron = Patron.create(:full_name => self.username) if self.username
    end
  end

  def set_lock_information
    if self.locked == '1' and self.active_for_authentication?
      lock_access!
    elsif self.locked == '0' and !self.active_for_authentication?
      unlock_access!
    end
  end

  def set_confirmation
    if operator and respond_to?(:confirm!)
      reload
      confirm!
    end
  end

  def index_patron
    if self.patron
      self.patron.index
    end
  end

  def check_expiration
    return if self.has_role?('Administrator')
    if expired_at
      if expired_at.beginning_of_day < Time.zone.now.beginning_of_day
        lock_access! if self.active_for_authentication?
      end
    end
  end

  def set_expired_at
    if self.user_group.valid_period_for_new_user > 0
      self.expired_at = self.user_group.valid_period_for_new_user.days.from_now.end_of_day
    end
  end

  def check_role_before_destroy
    if self.has_role?('Administrator')
      raise 'This is the last administrator in this system.' if Role.find_by_name('Administrator').users.size == 1
    end
  end

  def set_auto_generated_password
    password = Devise.friendly_token[0..7]
    self.reset_password!(password, password)
  end

  def reset_answer_feed_token
    self.answer_feed_token = Devise.friendly_token
  end

  def delete_answer_feed_token
    self.answer_feed_token = nil
  end

  def self.lock_expired_users
    User.find_each do |user|
      user.lock_access! if user.expired? and user.active_for_authentication?
    end
  end

  def expired?
    if expired_at
      true if expired_at.beginning_of_day < Time.zone.now.beginning_of_day
    end
  end

  def is_admin?
    true if self.has_role?('Administrator')
  end

  def last_librarian?
    if self.has_role?('Librarian')
      role = Role.where(:name => 'Librarian').first
      true if role.users.size == 1
    end
  end

  def send_message(status, options = {})
    MessageRequest.transaction do
      request = MessageRequest.new
      request.sender = User.find(1)
      request.receiver = self
      request.message_template = MessageTemplate.localized_template(status, self.locale)
      request.save_message_body(options)
      request.sm_send_message!
    end
  end

  def owned_tags_by_solr
    bookmark_ids = bookmarks.collect(&:id)
    if bookmark_ids.empty?
      []
    else
      Tag.bookmarked(bookmark_ids)
    end
  end

  def check_update_own_account(user)
    if user == self
      self.update_own_account = true
      return true
    end
    false
  end

  def send_confirmation_instructions
    unless self.operator
      Devise::Mailer.confirmation_instructions(self).deliver if self.email.present?
    end
  end

  def self.create_with_params(params, current_user)
    user = User.new(params)
    user.operator = current_user
    if params[:user]
      #self.username = params[:user][:login]
      user.note = params[:note]
      user.user_group_id = params[:user_group_id] ||= 1
      user.library_id = params[:library_id] ||= 1
      user.role_id = params[:role_id] ||= 1
      user.required_role_id = params[:required_role_id] ||= 1
      user.keyword_list = params[:keyword_list]
      user.user_number = params[:user_number]
      user.locale = params[:locale]
    end
    if user.patron_id
      user.patron = Patron.find(user.patron_id) rescue nil
    end
    user
  end

  def update_with_params(params, current_user)
    self.operator = current_user
    #self.username = params[:login]
    self.openid_identifier = params[:openid_identifier]
    self.keyword_list = params[:keyword_list]
    self.checkout_icalendar_token = params[:checkout_icalendar_token]
    self.email = params[:email]
    #self.note = params[:note]

    if current_user.has_role?('Librarian')
      self.note = params[:note]
      self.user_group_id = params[:user_group_id] || 1
      self.library_id = params[:library_id] || 1
      self.role_id = params[:role_id]
      self.required_role_id = params[:required_role_id] || 1
      self.user_number = params[:user_number]
      self.locale = params[:locale]
      self.locked = params[:locked]
      self.expired_at = params[:expired_at]
    end
    self
  end
end
