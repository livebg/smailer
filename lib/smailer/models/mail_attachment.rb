require 'open-uri'

module Smailer
  module Models
    class MailAttachment < ActiveRecord::Base
      belongs_to :mail_template, :inverse_of => :attachments

      validates_presence_of :path
      validates_presence_of :filename
      validates_presence_of :mail_template

      def body
        open(self.path).read
      end
    end
  end
end
