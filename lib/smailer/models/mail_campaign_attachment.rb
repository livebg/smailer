require 'open-uri'

module Smailer
  module Models
    class MailCampaignAttachment < ActiveRecord::Base

      belongs_to :mail_campaign
      validates_presence_of :mail_campaign_id
      validates_numericality_of :mail_campaign_id
      validates_presence_of :path
      validates_presence_of :filename

      def body
        open(self.path).read
      end

    end
  end
end
