FactoryGirl.define do
  factory :mailing_list, class: Smailer::Models::MailingList do
    name { "Mailing List #{generate(:name)}" }
  end

  factory :mail_template, class: Smailer::Models::MailTemplate do
    from    { generate(:email) }
    subject 'Hi there'
    body_html '<h1>Hi there</h1>'
    body_text '<h1>Hi there</h1>'
  end

  factory :mail_campaign, class: Smailer::Models::MailCampaign do
    association :mailing_list

    after(:build) do |mail_campaign|
      mail_campaign.mail_template ||= FactoryGirl.build(:mail_template)
    end
  end

  factory :queued_mail, class: Smailer::Models::QueuedMail do
    association :mail_campaign

    to { generate(:email) }
  end
end
