require 'mail'

module Smailer
  module Tasks
    class Send
      def self.execute(options = {})
        options.reverse_merge! :verp => !options[:return_path_domain].blank?

        # validate options
        if options[:verp] && options[:return_path_domain].blank?
          raise "VERP is enabled, but a :return_path_domain option has not been specified or is blank."
        end

        rails_delivery_method = if Compatibility.rails_3?
          Rails.configuration.action_mailer.delivery_method
        else
          ActionMailer::Base.delivery_method
        end

        Mail.defaults do
          delivery_method rails_delivery_method
        end

        batch_size   = (Smailer::Models::Property.get('queue.batch_size') || 100).to_i
        max_retries  = (Smailer::Models::Property.get('queue.max_retries') || 0).to_i
        max_lifetime = (Smailer::Models::Property.get('queue.max_lifetime') || 172800).to_i

        results = []

        # clean up any old locked items
        Smailer::Models::QueuedMail.update_all({:locked => false}, ['locked = ? AND locked_at <= ?', true, 1.hour.ago.utc])

        # load the queue items to process
        items_to_process = if Compatibility.rails_3?
          Smailer::Models::QueuedMail.where(:locked => false).order(:retries.asc, :id.asc).limit(batch_size)
        else
          Smailer::Models::QueuedMail.all(:conditions => {:locked => false}, :order => 'retries ASC, id ASC', :limit => batch_size)
        end

        # lock the queue items
        Smailer::Models::QueuedMail.update_all({:locked => true, :locked_at => Time.now.utc}, {:id => items_to_process.map(&:id)})

        items_to_process.each do |queue_item|
          # try to send the email
          mail = Mail.new do
            from    queue_item.from
            to      queue_item.to
            subject queue_item.subject

            text_part { body queue_item.body_text }
            html_part { body queue_item.body_html; content_type 'text/html; charset=UTF-8' }
          end
          mail.raise_delivery_errors = true

          # compute the VERP'd return_path if requested
          # or fall-back to a global return-path if not
          item_return_path = if options[:verp]
             "bounces-#{queue_item.key}@#{options[:return_path_domain]}"
          else
            options[:return_path]
          end

          # set the return-path, if any
          if item_return_path
            mail.return_path   = item_return_path
            mail['Errors-To']  = item_return_path
            mail['Bounces-To'] = item_return_path
          end

          queue_item.last_retry_at = Time.now
          queue_item.retries      += 1
          queue_item.locked        = false # unlock this email

          begin
            # commense delivery
            mail.deliver
          rescue Exception => e
            # failed, we have.
            queue_item.last_error = "#{e.class.name}: #{e.message}"
            queue_item.save

            # check if the message hasn't expired;
            retries_exceeded = max_retries  > 0 && queue_item.retries >= max_retries
            too_old = max_lifetime > 0 && (Time.now - queue_item.created_at) >= max_lifetime

            if retries_exceeded || too_old
              # the message has expired; move to finished_mails
              Smailer::Models::FinishedMail.add(queue_item, Smailer::Models::FinishedMail::Statuses::FAILED)
            end
            results.push [queue_item, :failed]
          else
            # great job, message sent
            Smailer::Models::FinishedMail.add(queue_item, Smailer::Models::FinishedMail::Statuses::SENT)
            results.push [queue_item, :sent]
          end
        end

        results
      end
    end
  end
end