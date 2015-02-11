module Smailer
  module Models
    class FinishedMail < ActiveRecord::Base
      class Statuses
        FAILED = 0
        SENT   = 1
      end

      belongs_to :mail_campaign

      validates_presence_of :mail_campaign_id, :from, :to, :retries, :status
      validates_numericality_of :mail_campaign_id, :retries, :status, :only_integer => true, :allow_nil => true
      validates_length_of :from, :to, :subject, :last_error, :maximum => 255, :allow_nil => true
      validates_uniqueness_of :key, :allow_nil => true

      delegate :mailing_list, :to => :mail_campaign, :allow_nil => true

      before_save :update_mail_campaign_counts

      def status_text
        Statuses.constants.each do |constant_name|
          return constant_name if Statuses.const_get(constant_name) == status
        end
        nil
      end

      def opened!
        self.opened = true
        Compatibility.save_without_validation self if changed?
      end

      def self.add(queued_mail, status = Statuses::SENT, update_sent_mails_count = true)
        finished = self.new

        fields_to_copy = [:mail_campaign_id, :key, :from, :to, :subject, :retries, :last_retry_at, :last_error]
        fields_to_copy += [:body_html, :body_text] if Smailer::Models::Property.get_boolean('finished_mails.preserve_body')

        fields_to_copy.each do |field|
          finished.send("#{field}=", queued_mail.send(field))
        end

        finished.status = status
        finished.sent_at = Time.now if status == Statuses::SENT

        finished.save!
        queued_mail.destroy
        queued_mail.delete

        if update_sent_mails_count && finished.mail_campaign
          finished.mail_campaign.sent_mails_count += 1
          Compatibility.save_without_validation finished.mail_campaign
        end

        finished
      end

      protected

      def update_mail_campaign_counts
        if opened_changed? && mail_campaign
          mail_campaign.opened_mails_count += opened_was ? -1 : 1
          Compatibility.save_without_validation mail_campaign
        end
      end
    end
  end
end
