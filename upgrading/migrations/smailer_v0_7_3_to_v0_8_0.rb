class SmailerV073ToV080 < ActiveRecord::Migration
  class MailCampaign < ActiveRecord::Base
    has_one :mail_template
    has_many :mail_attachments
  end

  class MailTemplate < ActiveRecord::Base
    belongs_to :mail_campaign
    belongs_to :queued_mail, :dependent => :destroy

    has_many :mail_attachments
  end

  class MailAttachment < ActiveRecord::Base
    belongs_to :mail_campaign
    belongs_to :mail_template
  end

  class QueuedMail < ActiveRecord::Base
    has_one :queued_mail
  end

  def self.up
    create_table :mail_templates do |t|
      t.references :mail_campaign
      t.references :queued_mail

      t.string :from
      t.string :subject
      t.text   :body_html
      t.text   :body_text

      t.timestamps
    end

    add_index :mail_templates, :mail_campaign_id
    add_index :mail_templates, :queued_mail_id

    rename_table :mail_campaign_attachments, :mail_attachments

    add_column :mail_attachments, :mail_template_id, :integer
    add_index :mail_attachments, :mail_template_id

    MailCampaign.all.each do |mail_campaign|
      mail_template = MailTemplate.new

      mail_template.mail_campaign    = mail_campaign
      mail_template.mail_attachments = mail_campaign.mail_attachments
      mail_template.from             = mail_campaign.from
      mail_template.subject          = mail_campaign.subject
      mail_template.body_html        = mail_campaign.body_html
      mail_template.body_text        = mail_campaign.body_text

      mail_template.save!
    end

    remove_column :mail_attachments, :mail_campaign_id

    remove_column :mail_campaigns, :from
    remove_column :mail_campaigns, :subject
    remove_column :mail_campaigns, :body_html
    remove_column :mail_campaigns, :body_text

    add_column :queued_mails, :require_uniqueness, :boolean, :default => true

    remove_index :queued_mails, :name => 'index_queued_mails_on_mail_campain_id_and_to'
    add_index    :queued_mails, [:mail_campaign_id, :to, :require_uniqueness], :name => 'index_queued_mails_uniqueness_for_to', :unique => true
  end

  def self.down
    remove_index :queued_mails, :name => 'index_queued_mails_uniqueness_for_to'
    add_index :queued_mails, [:mail_campaign_id, :to], :name => 'index_queued_mails_on_mail_campain_id_and_to', :unique => true

    QueuedMail.destroy_all('require_uniqueness is null')

    remove_column :queued_mails, :require_uniqueness

    MailTemplate.destroy_all('queued_mail_id is not null')

    add_column :mail_campaigns, :from, :string
    add_column :mail_campaigns, :subject, :string
    add_column :mail_campaigns, :body_html, :text
    add_column :mail_campaigns, :body_text, :text

    add_column :mail_attachments, :mail_campaign_id, :integer
    add_index :mail_attachments, :mail_campaign_id

    MailCampaign.all.each do |mail_campaign|
      mail_template = mail_campaign.mail_template

      mail_campaign.mail_attachments = mail_template.mail_attachments

      mail_campaign.from      = mail_template.from
      mail_campaign.subject   = mail_template.subject
      mail_campaign.body_html = mail_template.body_html
      mail_campaign.body_text = mail_template.body_text

      mail_campaign.save!
    end

    remove_column :mail_attachments, :mail_template_id
    rename_table :mail_attachments, :mail_campaign_attachments

    drop_table :mail_templates
  end
end
