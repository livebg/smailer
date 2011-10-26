module Smailer
  module Tasks
    autoload :Send, 'smailer/tasks/send'
    autoload :ProcessBounces, 'smailer/tasks/process_bounces'
  end
end