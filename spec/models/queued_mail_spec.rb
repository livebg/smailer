require 'spec_helper'

describe Smailer::Models::QueuedMail do
  describe '#save' do
    it 'could be made only with mail_campaign and to (recipient)' do
      mail_campaign = FactoryGirl.create(:mail_campaign)

      queued_mail = Smailer::Models::QueuedMail.new

      queued_mail.mail_campaign = mail_campaign
      queued_mail.to = 'test@example.com'

      expect(Smailer::Models::MailCampaign.count).to eq(1)
      expect(Smailer::Models::MailTemplate.count).to eq(1)
      expect(Smailer::Models::QueuedMail.count).to eq(0)

      queued_mail.save!

      expect(Smailer::Models::MailCampaign.count).to eq(1)
      expect(Smailer::Models::MailTemplate.count).to eq(1)
      expect(Smailer::Models::QueuedMail.count).to eq(1)

      queued_mail.reload

      expect(queued_mail.to).to eq('test@example.com')
    end

    it 'would create its own template if you change any of the template attributes and will copy the mail_campaign template' do
      mail_campaign = FactoryGirl.create(:mail_campaign)
      mail_campaign.add_attachment 'foo.pdf', '/tmp/foo.pdf'
      mail_campaign.save!

      queued_mail = Smailer::Models::QueuedMail.new

      queued_mail.mail_campaign = mail_campaign
      queued_mail.to = 'text@example.com'

      queued_mail.from = 'sender@example.com'

      queued_mail.save!

      mail_campaign.reload
      queued_mail.reload

      expect(queued_mail.from).to      eq('sender@example.com')
      expect(queued_mail.body_html).to eq(mail_campaign.body_html)
      expect(queued_mail.body_text).to eq(mail_campaign.body_text)
      expect(queued_mail.subject).to   eq(mail_campaign.subject)

      expect(queued_mail.attachments).to be_present
      expect(mail_campaign.attachments).to be_present
      expect(queued_mail.attachments.first.path).to eq(mail_campaign.attachments.first.path)
      expect(queued_mail.attachments.first.filename).to eq(mail_campaign.attachments.first.filename)

      expect(queued_mail.mail_template).to_not     eq(mail_campaign.mail_template)
      expect(queued_mail.attachments.first).to_not eq(mail_campaign.attachments.first)

      expect(Smailer::Models::MailCampaign.count).to eq(1)
      expect(Smailer::Models::MailTemplate.count).to eq(2)
      expect(Smailer::Models::MailAttachment.count).to eq(2)
      expect(Smailer::Models::QueuedMail.count).to eq(1)
    end
  end

  describe '#key' do
    it 'is unique per email' do
      mail_campaign = FactoryGirl.create(:mail_campaign)

      queued_mail_1 = Smailer::Models::QueuedMail.new
      queued_mail_1.mail_campaign = mail_campaign
      queued_mail_1.to = 'text@example.com'

      queued_mail_2 = Smailer::Models::QueuedMail.new
      queued_mail_2.mail_campaign = mail_campaign
      queued_mail_2.to = 'text@example.com'

      expect(queued_mail_1.key).to_not eq(queued_mail_2.key)
    end
  end
end
