require 'spec_helper.rb'

describe 'Issuing a newsletter' do
  describe 'the example from the readme' do
    before do
      # Required setup not from the readme
      FactoryGirl.create(:mailing_list)
    end

    it 'works as expected' do
      # locate the mailing list we'll be sending to
      list = Smailer::Models::MailingList.first

      # create a corresponding mail campaign
      campaign_params = {
        :from      => 'noreply@example.org',
        :reply_to  => 'contact@example.org',
        :subject   => 'My First Campaign!',
        :body_html => '<h1>Hello</h1><p>World</p>',
        :body_text => 'Hello, world!',
        :mailing_list_id => list.id,
      }
      campaign = Smailer::Models::MailCampaign.new campaign_params
      campaign.add_unsubscribe_method :all

      # Add attachments
      campaign.add_attachment 'attachment.pdf', 'url_or_file_path_to_attachment'

      campaign.save!

      # enqueue mails to be sent out
      subscribers = %w[
        subscriber@domain.com
        office@company.com
        contact@store.com
      ]
      subscribers.each do |subscriber|
        campaign.queued_mails.create! :to => subscriber
      end

      expect(Smailer::Models::MailCampaign.count).to eq(1)
      expect(Smailer::Models::MailTemplate.count).to eq(1)
      expect(Smailer::Models::MailAttachment.count).to eq(1)
      expect(Smailer::Models::QueuedMail.count).to eq(3)

      expect(campaign.from).to            eq(campaign_params[:from])
      expect(campaign.subject).to         eq(campaign_params[:subject])
      expect(campaign.body_html).to       eq(campaign_params[:body_html])
      expect(campaign.body_text).to       eq(campaign_params[:body_text])
      expect(campaign.mailing_list_id).to eq(campaign_params[:mailing_list_id])
    end
  end
end
