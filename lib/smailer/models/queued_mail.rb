class QueuedMail < ActiveRecord::Base
  belongs_to :mail_campaign

  validates_presence_of :mail_campaign_id, :to
  validates_uniqueness_of :to, :scope => :mail_campaign_id
  validates_numericality_of :mail_campaign_id, :retries, :only_integer => true, :allow_nil => true
  validates_length_of :to, :last_error, :maximum => 255

  attr_accessible :mail_campaign_id, :to

  delegate :from, :subject, :mailing_list, :to => :mail_campaign, :allow_nil => true

  def body_html
    interpolate mail_campaign.body_html
  end

  def body_text
    interpolate mail_campaign.body_text
  end

  protected

  def interpolate(text)
    {
      :email           => to,
      :escaped_email   => lambda { ERB::Util.h(to) },
      :email_key       => lambda { MailKey.get(to) },
      :mailing_list_id => lambda { mailing_list.id },
    }.each do |variable, interpolation|
      text.gsub! "%{#{variable}}" do
        interpolation.respond_to?(:call) ? interpolation.call : interpolation.to_s
      end
    end

    text
  end
end
