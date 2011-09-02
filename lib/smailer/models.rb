module Smailer
  module Models
    autoload :MailingList,    'smailer/models/mailing_list'
    autoload :MailCampaign,   'smailer/models/mail_campaign'
    autoload :MailKey,        'smailer/models/mail_key'
    autoload :QueuedMail,     'smailer/models/queued_mail'
    autoload :FinishedMail,   'smailer/models/finished_mail'
    autoload :Property,       'smailer/models/property'
  end
end