module Smailer
  module Models
    autoload :MailingList,    'models/mailing_list'
    autoload :MailCampaign,   'models/mail_campaign'
    autoload :MailKey,        'models/mail_key'
    autoload :QueuedMail,     'models/queued_mail'
    autoload :FinishedMail,   'models/finished_mail'
    autoload :Property,       'models/property'
  end
end