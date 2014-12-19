module Smailer
  module Models
    class MailCampaign < ActiveRecord::Base
      class UnsubscribeMethods
        URL     = 1
        REPLY   = 2
        BOUNCED = 4
      end

      belongs_to :mailing_list
      has_many :queued_mails, :dependent => :destroy
      has_many :finished_mails, :dependent => :destroy
      has_many :attachments,
               :class_name => '::Smailer::Models::MailCampaignAttachment'

      validates_presence_of :mailing_list_id, :from
      validates_numericality_of :mailing_list_id, :unsubscribe_methods, :only_integer => true, :allow_nil => true
      validates_length_of :from, :subject, :maximum => 255, :allow_nil => true

      unless Smailer::Compatibility.rails_4?
        attr_accessible :mailing_list_id, :from, :subject, :body_html, :body_text
      end

      def add_unsubscribe_method(method_specification)
        unsubscribe_methods_list_from(method_specification).each do |method|
          self.unsubscribe_methods = (self.unsubscribe_methods || 0) | method
        end
      end

      def remove_unsubscribe_method(method_specification)
        unsubscribe_methods_list_from(method_specification).each do |method|
          if has_unsubscribe_method?(method)
            self.unsubscribe_methods = (self.unsubscribe_methods || 0) ^ method
          end
        end
      end

      def has_unsubscribe_method?(method)
        (unsubscribe_methods || 0) & method === method
      end

      def active_unsubscribe_methods
        self.class.unsubscribe_methods.reject do |method, method_name|
          not has_unsubscribe_method?(method)
        end
      end

      def name
        "Campaign ##{id} (#{mailing_list.name})"
      end

      def hit_rate
        return nil if sent_mails_count == 0
        opened_mails_count.to_f / sent_mails_count
      end

      def add_attachment(filename, path)
        self.attachments.create!(:filename => filename, :path => path)
      end

      def self.unsubscribe_methods
        methods = {}
        UnsubscribeMethods.constants.map do |method_name|
          methods[UnsubscribeMethods.const_get(method_name)] = method_name
        end

        methods
      end

      private

      def unsubscribe_methods_list_from(method_specification)
        if method_specification == :all
          self.class.unsubscribe_methods.keys
        else
          [method_specification]
        end
      end
    end
  end
end