require 'mail'

module Smailer
  module Tasks
    class Send
      def self.execute
        Mail.defaults do
          delivery_method Rails.configuration.action_mailer.delivery_method
        end

        batch_size   = (Smailer::Models::Property.get('queue.batch_size') || 100).to_i
        max_retries  = (Smailer::Models::Property.get('queue.max_retries') || 0).to_i
        max_lifetime = (Smailer::Models::Property.get('queue.max_lifetime') || 172800).to_i

        results = []

        items_to_process = if Compatibility.rails_3?
          Smailer::Models::QueuedMail.order(:retries.asc, :id.asc).limit(batch_size)
        else
          Smailer::Models::QueuedMail.all(:order => 'retries ASC, id ASC', :limit => batch_size)
        end

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

          queue_item.last_retry_at = Time.now
          queue_item.retries += 1

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