module Smailer
  module Models
    autoload :MailingList,    'smailer/models/mailing_list'
    autoload :MailTemplate,   'smailer/models/mail_template'
    autoload :MailCampaign,   'smailer/models/mail_campaign'
    autoload :MailAttachment, 'smailer/models/mail_attachment'
    autoload :MailKey,        'smailer/models/mail_key'
    autoload :QueuedMail,     'smailer/models/queued_mail'
    autoload :FinishedMail,   'smailer/models/finished_mail'
    autoload :Property,       'smailer/models/property'
  end
end
