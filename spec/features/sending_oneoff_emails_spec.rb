require 'spec_helper.rb'

describe 'Sending one-off emails' do
  describe 'the example from the readme' do
    before do
      # Required setup not from the readme
      FactoryGirl.create(:mail_campaign)
    end

    it 'works as expected' do
      campaign = Smailer::Models::MailCampaign.first

      # The mail template is copied from the campaign and then you make you changes
      # e.g. here the subject and from are copied from the campaign
      campaign.queued_mails.create! :to => 'subscriber@domain.com', :body_html => '<h1>my custom body</h1>', :body_text => 'my custom body'

      # if you change the campaign now it won't change the one-off queued_mails

      # sending two mails to the same person
      campaign.queued_mails.create! :to => 'subscriber@domain.com', :body_html => '<h1>second custom body</h1>', :body_text => 'second custom body', :require_uniqueness => false

      expect(Smailer::Models::MailCampaign.count).to eq(1)
      expect(Smailer::Models::MailTemplate.count).to eq(3) # 1 for the campaign and 2 for the one-off emails
      expect(Smailer::Models::MailAttachment.count).to eq(0)
      expect(Smailer::Models::QueuedMail.count).to eq(2)

      first_mail = campaign.queued_mails.first

      expect(first_mail.from).to      eq(campaign.from)
      expect(first_mail.subject).to   eq(campaign.subject)
      expect(first_mail.body_html).to eq('<h1>my custom body</h1>')
      expect(first_mail.body_text).to eq('my custom body')

      second_mail = campaign.queued_mails.last

      expect(second_mail.from).to      eq(campaign.from)
      expect(second_mail.subject).to   eq(campaign.subject)
      expect(second_mail.body_html).to eq('<h1>second custom body</h1>')
      expect(second_mail.body_text).to eq('second custom body')
    end
  end
end
