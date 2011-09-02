class FinishedMail < ActiveRecord::Base
  class Statuses
    FAILED = 0
    SENT   = 1
  end

  belongs_to :mail_campaign

  validates_presence_of :mail_campaign_id, :from, :to, :retries, :status
  validates_numericality_of :mail_campaign_id, :retries, :status, :only_integer => true, :allow_nil => true
  validates_length_of :from, :to, :subject, :last_error, :maximum => 255

  delegate :mailing_list, :to => :mail_campaign, :allow_nil => true

  def status_text
    Statuses.constants.each do |constant_name|
      return constant_name if Statuses.const_get(constant_name) == status
    end
    nil
  end

  def self.add(queued_mail, status = Statuses::SENT)
    finished = self.new

    [:mail_campaign_id, :from, :to, :subject, :body_html, :body_text, :retries, :last_retry_at, :last_error].each do |field|
      finished.send("#{field}=", queued_mail.send(field))
    end

    finished.status = status
    finished.sent_at = Time.now if status == Statuses::SENT

    finished.save!
    queued_mail.destroy

    finished
  end
end
