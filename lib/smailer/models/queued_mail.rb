require 'digest/md5'
require 'securerandom'

module Smailer
  module Models
    class QueuedMail < ActiveRecord::Base
      belongs_to :mail_campaign

      has_one :mail_template, :dependent => :destroy, :autosave => true, :inverse_of => :queued_mail
      has_many :attachments, :through => :mail_template

      validates_presence_of :mail_campaign_id, :to
      validates_uniqueness_of :to, :scope => :mail_campaign_id, if: proc { |queued_mail| queued_mail.require_uniqueness }
      validates_uniqueness_of :key
      validates_numericality_of :mail_campaign_id, :retries, :only_integer => true, :allow_nil => true
      validates_length_of :to, :last_error, :maximum => 255, :allow_nil => true

      unless Smailer::Compatibility.rails_4?
        attr_accessible :mail_campaign_id, :to, :from, :subject, :body_html, :body_text, :require_uniqueness
      end

      before_validation :initialize_message_key
      before_save :initialize_message_key

      before_save :nullify_false_require_uniqueness

      delegate :mailing_list, :to => :mail_campaign, :allow_nil => true
      delegate :from, :subject, :to => :active_mail_template, :allow_nil => true
      delegate :from=, :subject=, :body_html=, :body_text, :to => :my_mail_template

      def body_html
        interpolate active_mail_template.body_html
      end

      def body_text
        interpolate active_mail_template.body_text
      end

      def key
        initialize_message_key
        self[:key]
      end

      def attachments
        active_mail_template.attachments
      end

      def add_attachment(filename, path)
        my_mail_template.attachments.build(:filename => filename, :path => path)
      end

      protected

      def active_mail_template
        mail_template || mail_campaign.try(:mail_template)
      end

      def my_mail_template
        return mail_template if mail_template.present?

        build_mail_template.tap do |template|
          if mail_campaign.present?
            campaign_template = mail_campaign.mail_template

            template.from      = campaign_template.from
            template.subject   = campaign_template.subject
            template.body_html = campaign_template.body_html
            template.body_text = campaign_template.body_text

            template.attachments = campaign_template.attachments.map(&:dup)
          end
        end
      end

      def initialize_message_key
        self.key = Digest::MD5.hexdigest("#{mail_campaign_id}, #{to}, #{SecureRandom.hex(15)} and #{id} compose this key.")
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

      # Prevents the unique index in the database from firing
      def nullify_false_require_uniqueness
        unless self.require_uniqueness
          self.require_uniqueness = nil
        end
      end
    end
  end
end
