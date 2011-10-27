require 'bounce_email'
require 'net/pop'

module Smailer
  module Tasks
    class ProcessBounces
      @@keys_messages  = {}
      @@bounce_counts  = Hash.new(0)
      @@emails_bounces = {}
      @@unsubscribed   = {}
      @@test_mode      = false

      class << self
        # You need to provide at least a :server, :username and a :password options to execute().
        # These will represent the POP3 connection details to the bounce mailbox which will be processed.
        # Also consider providing a concrete implementation to the :subscribed_checker option, so that
        # bounces for unknown or already-unsubscribed emails do not remain clogging-up the mailbox
        # Example usage:
        #
        # Smailer::Tasks::ProcessBounces.execute({
        #   :server           => 'bounces.example.org',
        #   :username         => 'noreply@bounces.example.org',
        #   :password         => 'somesecret',
        #   :subscribed_checker => lambda { |recipient| Subscribers.subscribed.where(:email => recipient).first.present? },
        # }) do |unsubscribe_details|
        #   Subscribers.where(:email => unsubscribe_details[:recipient]).destroy
        # end
        def execute(options = {})
          deleted = 0
          options = {
            :port => 110,
            :subscribed_checker => lambda { true },
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

          connect_to_mailbox(options) do |pop|
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

                  if !unsubscribed?(recipient) && options[:subscribed_checker].call(recipient)
                    processed = true
                    register_bounce recipient, bounce, m

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

              if options[:delete_unprocessed_bounces] && !processed
                m.delete unless test_mode?
                deleted += 1
              end
            end
          end

          logger.call "Deleted #{deleted} unprocessed bounce(s) from the mailbox" if deleted > 0
          connect_to_mailbox(options) { |pop| logger.call "Messages left in the mailbox: #{pop.mails.size}" }
        end

        def test_mode?
          @@test_mode
        end

        def test_mode=(mode)
          @@test_mode = mode
        end

        private

        def connect_to_mailbox(options, &block)
          Net::POP3.start(options[:server], options[:port], options[:username], options[:password], &block)
        end

        def unsubscribed?(recipient)
          @@unsubscribed[recipient]
        end

        def unsubscribe(recipient)
          @@unsubscribed[recipient] = true

          bounces_for(recipient).each do |pop_mail|
            pop_mail.delete unless test_mode?
          end

          @@emails_bounces[recipient] = nil
        end

        def register_bounce(recipient, bounce, pop_mail)
          increment_bounce_count_for recipient, bounce.code
          bounces_for(recipient) << pop_mail
        end

        def bounces_for(recipient)
          @@emails_bounces[recipient] ||= []
        end

        def bounce_count_for(email, error_code = nil)
          key = [email, error_code]
          @@bounce_counts[key]
        end

        def increment_bounce_count_for(email, error_code = nil)
          [error_code, nil].uniq.each do |code|
            @@bounce_counts[[email, code]] += 1
          end
        end

        def sent_message_from_bounce(mail)
          to  = mail.to.select { |address| address.to_s.start_with? Smailer::BOUNCES_PREFIX }.first
          return nil if to.nil?

          key = to.strip.split('@').first[Smailer::BOUNCES_PREFIX.size..-1]

          @@keys_messages[key] ||= if Smailer::Compatibility.rails_3?
            Smailer::Models::FinishedMail.where(:key => key).first
          else
            Smailer::Models::FinishedMail.first(:conditions => {:key => key})
          end
        end
      end
    end
  end
end
