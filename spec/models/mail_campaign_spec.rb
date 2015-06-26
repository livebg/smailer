require 'spec_helper'

describe Smailer::Models::MailCampaign do
  describe '#save' do
    it 'works as expected' do
      mail_campaign = Smailer::Models::MailCampaign.new

      mail_campaign.mailing_list = FactoryGirl.create(:mailing_list)

      mail_campaign.from = '"test" <test@example.com>'
      mail_campaign.subject = 'This is my test'
      mail_campaign.body_html = 'Hello html'
      mail_campaign.body_text = 'Hello text'

      mail_campaign.add_attachment 'foo.pdf', '/tmp/foo.pdf'

      expect(Smailer::Models::MailCampaign.count).to eq(0)
      expect(Smailer::Models::MailTemplate.count).to eq(0)
      expect(Smailer::Models::MailAttachment.count).to eq(0)

      mail_campaign.save!

      expect(Smailer::Models::MailCampaign.count).to eq(1)
      expect(Smailer::Models::MailTemplate.count).to eq(1)
      expect(Smailer::Models::MailAttachment.count).to eq(1)
    end
  end
end
