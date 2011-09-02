class MailingList < ActiveRecord::Base
  has_many :mail_campaigns

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 255

  attr_accessible :name
end
