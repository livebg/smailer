require 'digest/md5'

module Smailer
  module Models
    class QueuedMail < ActiveRecord::Base
      belongs_to :mail_campaign

      validates_presence_of :mail_campaign_id, :to
      validates_uniqueness_of :to, :scope => :mail_campaign_id
      validates_uniqueness_of :key
      validates_numericality_of :mail_campaign_id, :retries, :only_integer => true, :allow_nil => true
      validates_length_of :to, :last_error, :maximum => 255, :allow_nil => true

      unless Smailer::Compatibility.rails_4?
        attr_accessible :mail_campaign_id, :to
      end

      delegate :from, :subject, :mailing_list, :to => :mail_campaign, :allow_nil => true

      before_validation :initialize_message_key
      before_save :initialize_message_key

      def body_html
        interpolate mail_campaign.body_html
      end

      def body_text
        interpolate mail_campaign.body_text
      end

      def key
        initialize_message_key
        self[:key]
      end

      protected

      def initialize_message_key
        self.key = Digest::MD5.hexdigest("#{mail_campaign_id}, #{to} and #{id} compose this key.")
      end

      def interpolate(text)
        return text if text.nil?

        {
          :email            => to,
          :escaped_email    => lambda { ERB::Util.h(to) },
          :email_key        => lambda { MailKey.get(to) },
          :mailing_list_id  => lambda { mailing_list.id },
          :mail_campaign_id => mail_campaign_id,
          :message_key      => key,
        }.each do |variable, interpolation|
          text.gsub! "%{#{variable}}" do
            interpolation.respond_to?(:call) ? interpolation.call : interpolation.to_s
          end
        end

        text
      end
    end
  end
end
