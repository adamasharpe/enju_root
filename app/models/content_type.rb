class ContentType < ActiveRecord::Base
  default_scope :order => 'position'
  has_many :expressions

  validates_presence_of :name, :display_name
  validates_uniqueness_of :name
  acts_as_list

  def before_validation_on_create
    self.display_name = self.name if display_name.blank?
  end

  def after_save
    Rails.cache.delete('ContentType.all')
  end

  def after_destroy
    after_save
  end
end
