module Smailer
  module Models
    class MailTemplate < ActiveRecord::Base
      belongs_to :mail_campaign, :inverse_of => :mail_template
      belongs_to :queued_mail, :inverse_of => :mail_template

      has_many :attachments, :class_name => '::Smailer::Models::MailAttachment', :autosave => true, :inverse_of => :mail_template

      validates_presence_of :from
      validates_length_of :from, :subject, :maximum => 255, :allow_nil => true
    end
  end
end
