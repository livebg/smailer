require 'spec_helper'

describe Smailer::Models::QueuedMail do
  describe '.new' do
    it 'will fill the mail_template from the mail_campaign as expected' do
      mail_campaign = FactoryGirl.create(:mail_campaign, :subject => 'Campaign subject', :from => 'from@campaign.com')

      queued_mail = Smailer::Models::QueuedMail.new(
        :to        => 'someone@world.com',
        :reply_to  => 'reply@world.com',
        :body_html => 'Custom html body',
        :body_text => 'Custom text body',
        :mail_campaign => mail_campaign
      )

      queued_mail.valid?
      expect(queued_mail.errors).to be_blank

      expect(queued_mail.from).to      eq('from@campaign.com')
      expect(queued_mail.subject).to   eq('Campaign subject')
      expect(queued_mail.reply_to).to  eq('reply@world.com')
      expect(queued_mail.body_html).to eq('Custom html body')
      expect(queued_mail.body_text).to eq('Custom text body')
    end
  end

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

    describe 'when changing the mail_template' do
      [
        {:from      => 'sender@example.com'},
        {:reply_to  => 'reply@example.com'},
        {:subject   => 'MY NEW SUBJECT'},
        {:body_html => 'NEW HTML BODY'},
        {:body_text => 'NEW TEXT BODY'},
      ].each do |changes|
        it "would copy the mail_campaign template and modify the copy - changing #{changes}" do
          mail_campaign = FactoryGirl.create(:mail_campaign)
          mail_campaign.add_attachment 'foo.pdf', '/tmp/foo.pdf'
          mail_campaign.save!

          queued_mail = Smailer::Models::QueuedMail.new

          queued_mail.mail_campaign = mail_campaign
          queued_mail.to = 'text@example.com'

          changes.each do |key, value|
            queued_mail.public_send("#{key}=", value)
          end

          queued_mail.save!

          mail_campaign.reload
          queued_mail.reload

          expect(queued_mail.from).to      eq(changes[:from]      || mail_campaign.from)
          expect(queued_mail.reply_to).to  eq(changes[:reply_to]  || mail_campaign.reply_to)
          expect(queued_mail.body_html).to eq(changes[:body_html] || mail_campaign.body_html)
          expect(queued_mail.body_text).to eq(changes[:body_text] || mail_campaign.body_text)
          expect(queued_mail.subject).to   eq(changes[:subject]   || mail_campaign.subject)

          expect(queued_mail.attachments).to be_present
          expect(mail_campaign.attachments).to be_present
          expect(queued_mail.attachments.first.filename).to eq(mail_campaign.attachments.first.filename)
          expect(queued_mail.attachments.first.path).to eq(mail_campaign.attachments.first.path)

          expect(queued_mail.mail_template).to_not     eq(mail_campaign.mail_template)
          expect(queued_mail.attachments.first).to_not eq(mail_campaign.attachments.first)

          expect(Smailer::Models::MailCampaign.count).to eq(1)
          expect(Smailer::Models::MailTemplate.count).to eq(2)
          expect(Smailer::Models::MailAttachment.count).to eq(2)
          expect(Smailer::Models::QueuedMail.count).to eq(1)
        end
      end

      it "would copy the mail_campaign template when adding an attachment" do
        mail_campaign = FactoryGirl.create(:mail_campaign)
        mail_campaign.add_attachment 'foo.pdf', '/tmp/foo.pdf'
        mail_campaign.save!

        queued_mail = Smailer::Models::QueuedMail.new

        queued_mail.mail_campaign = mail_campaign
        queued_mail.to = 'text@example.com'

        queued_mail.add_attachment('bar.pdf', '/tmp/bar.pdf')

        queued_mail.save!

        mail_campaign.reload
        queued_mail.reload

        expect(queued_mail.from).to      eq(mail_campaign.from)
        expect(queued_mail.body_html).to eq(mail_campaign.body_html)
        expect(queued_mail.body_text).to eq(mail_campaign.body_text)
        expect(queued_mail.subject).to   eq(mail_campaign.subject)

        expect(queued_mail.attachments).to be_present
        expect(mail_campaign.attachments).to be_present
        expect(queued_mail.attachments.first.filename).to eq(mail_campaign.attachments.first.filename)
        expect(queued_mail.attachments.first.path).to eq(mail_campaign.attachments.first.path)
        expect(queued_mail.attachments.last.filename).to eq('bar.pdf')
        expect(queued_mail.attachments.last.path).to eq('/tmp/bar.pdf')

        expect(queued_mail.mail_template).to_not     eq(mail_campaign.mail_template)
        expect(queued_mail.attachments.first).to_not eq(mail_campaign.attachments.first)

        expect(Smailer::Models::MailCampaign.count).to eq(1)
        expect(Smailer::Models::MailTemplate.count).to eq(2)
        expect(Smailer::Models::MailAttachment.count).to eq(3)
        expect(Smailer::Models::QueuedMail.count).to eq(1)
      end
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

    it 'remains the same once initialized' do
      queued_mail = Smailer::Models::QueuedMail.new
      queued_mail.mail_campaign_id = 42
      queued_mail.to = 'test@example.com'

      expect(SecureRandom).to receive(:hex).once.with(15).and_return('random-string')
      expect(Digest::MD5).to receive(:hexdigest).once.with('42, test@example.com, random-string compose this key.').and_return('message-key')

      expect(queued_mail.key).to eq('message-key')

      queued_mail.save!
      queued_mail.reload

      expect(queued_mail.key).to eq('message-key')
    end
  end

  describe '#require_uniqueness' do
    it 'is required by default' do
      mail_campaign = FactoryGirl.create(:mail_campaign)

      queued_mail_1 = Smailer::Models::QueuedMail.new
      queued_mail_1.mail_campaign = mail_campaign
      queued_mail_1.to = 'text@example.com'
      queued_mail_1.save!

      queued_mail_2 = Smailer::Models::QueuedMail.new
      queued_mail_2.mail_campaign = mail_campaign
      queued_mail_2.to = 'text@example.com'

      expect(queued_mail_2.save).to eq(false)
      expect(queued_mail_2.errors[:to]).to be_present
    end

    it 'could be turned off by setting it to false' do
      mail_campaign = FactoryGirl.create(:mail_campaign)

      queued_mail_1 = Smailer::Models::QueuedMail.new
      queued_mail_1.mail_campaign = mail_campaign
      queued_mail_1.to = 'text@example.com'
      queued_mail_1.save!

      queued_mail_2 = Smailer::Models::QueuedMail.new
      queued_mail_2.mail_campaign = mail_campaign
      queued_mail_2.to = 'text@example.com'
      queued_mail_2.require_uniqueness = false

      expect(queued_mail_2.save).to eq(true)
    end
  end
end
