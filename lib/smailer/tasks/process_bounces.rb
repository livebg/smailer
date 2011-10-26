require 'bounce_email'
require 'net/pop'

module Smailer
  module Tasks
    class ProcessBounces
      @@keys_messages  = {}
      @@bounce_counts  = Hash.new(0)
      @@emails_bounces = {}
      @@unsubscribed   = {}

      # You need to provide at least a :server, :username and a :password options to execute().
      # These will represent the POP3 connection details to the bounce mailbox which will be processed.
      # Also consider providing a concrete implementation to the :subscribed_check option, so that
      # bounces for unknown or already-unsubscribed emails do not remain clogging-up the mailbox
      # Example usage:
      #
      # Smailer::Tasks::ProcessBounces.execute({
      #   :server           => 'bounces.example.org',
      #   :username         => 'noreply@bounces.example.org',
      #   :password         => 'somesecret',
      #   :subscribed_check => lambda { |recipient| Subscribers.subscribed.where(:email => recipient).first.present? },
      # }) do |unsubscribe_details|
      #   Subscribers.where(:email => unsubscribe_details[:recipient]).destroy
      # end
      def self.execute(options = {})
        report  = []
        options = {
          :port => 110,
          :subscribed_check => lambda { true },
          :bounce_counts_per_type_to_unsubscribe => {
            1   => ['5.1.1', '5.1.2', '5.1.3', '5.1.6', '5.1.8', '5.7.1'],
            3   => ['5.2.1', '5.1.0'],
            5   => ['5.5.0'],
            8   => ['5.0.0'],
            12  => ['5.2.2', '5.2.0', '5.3.0', '5.3.2'],
            16  => ['4.2.2', '4.4.2', '4.0.0'],
            30  => ['97', '98', '99'],
          },
          :default_bounce_count_per_type_to_unsubscribe => 20,
          :total_bounce_count_to_unsubscribe => 40,
          :delete_unprocessed_bounces => true,
          :logger => lambda { |msg| puts msg },
        }.merge(options)

        logger = lambda do |msg|
          options[:logger].call msg if options[:logger] && options[:logger].respond_to?(:call)
        end

        Net::POP3.start(options[:server], options[:port], options[:username], options[:password]) do |pop|
          mails_to_process = pop.mails.size
          logger.call "#{mails_to_process} mail(s) to process"

          pop.mails.each_with_index do |m, i|
            logger.call "#{((i + 1) * 100.0 / mails_to_process).round(2)}% (#{i + 1} of #{mails_to_process})" if i % 200 == 0

            mail      = Mail.new m.pop
            bounce    = BounceEmail::Mail.new mail
            processed = false

            if bounce.bounced?
              original_email = sent_message_from_bounce(mail)

              if original_email
                recipient = original_email.to

                if !unsubscribed?(recipient) && options[:subscribed_check].call(recipient)
                  processed = true
                  register_bounce bounce, m

                  bounce_count_per_type = bounce_count_for recipient, bounce.code
                  total_bounce_count    = bounce_count_for recipient

                  rule = options[:bounce_counts_per_type_to_unsubscribe].select { |count, codes| codes.include?(bounce.code) }.first
                  max_count_per_type = rule ? rule.first : options[:default_bounce_count_per_type_to_unsubscribe]

                  bounce_count_per_type_exceeded = bounce_count_per_type >= max_count_per_type
                  total_bounce_count_exceeded    = total_bounce_count >= options[:total_bounce_count_to_unsubscribe]

                  if bounce_count_per_type_exceeded || total_bounce_count_exceeded
                    logger.call "=> Unsubscribing #{recipient} and deleting #{bounces_for(recipient).size} bounced email(s)"

                    yield :recipient => recipient, :original_email => original_email, :bounce => bounce
                    unsubscribe recipient
                  end
                end
              end
            end

              m.delete if options[:delete_unprocessed_bounces] && !processed
          end
        end

        report
      end

      private

      def self.unsubscribed?(recipient)
        @@unsubscribed[recipient]
      end

      def self.unsubscribe(recipient)
        @@unsubscribed[recipient] = true

        bounces_for(recipient).each do |pop_mail|
          pop_mail.delete
        end

        @@emails_bounces[recipient] = nil
      end

      def self.register_bounce(bounce, pop_mail)
        increment_bounce_count_for recipient, bounce.code
        bounces_for(recipient) << pop_mail
      end

      def self.bounces_for(recipient)
        @@emails_bounces[recipient] ||= []
      end

      def self.bounce_count_for(email, error_code = nil)
        key = [email, error_code]
        @@bounce_counts[key]
      end

      def self.increment_bounce_count_for(email, error_code = nil)
        [error_code, nil].uniq.each do |code|
          @@bounce_counts[[email, code]] += 1
        end
      end

      def self.sent_message_from_bounce(mail)
        to  = mail.to.select { |address| address.start_with? Smailer::BOUNCES_PREFIX }.first.to_s
        key = to.split('@').first[Smailer::BOUNCES_PREFIX.size..-1]

        @@keys_messages[key] ||= FinishedMail.where(:key => key).first
      end
    end
  end
end
