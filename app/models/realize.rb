class Realize < ActiveRecord::Base
  belongs_to :patron
  belongs_to :expression

  validates_associated :patron, :expression
  validates_presence_of :patron, :expression
  validates_uniqueness_of :expression_id, :scope => :patron_id
  after_save :reindex
  after_destroy :reindex

  acts_as_list :scope => :expression

  def self.per_page
    10
  end

  def reindex
    patron.index
    expression.index
  end

end
# == Schema Information
#
# Table name: realizes
#
#  id              :integer         not null, primary key
#  patron_id       :integer
#  patron_type     :string(255)
#  expression_id   :integer         not null
#  position        :integer
#  type            :string(255)
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#  realize_type_id :integer
#

