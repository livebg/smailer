# Simple newsletter mailer for Rails

## Intro

This project is a simple mailer for newsletters, which implements simple queue processing, basic campaign management, [VERP support](http://en.wikipedia.org/wiki/Variable_envelope_return_path), bounce processing and auto-unsubscribe of invalid emails and also assists you in implementing unsubscribe links in the email messages.

It is intended to be used within a Rails project.

### Supported versions of Rails

It has been tested with Rails 3.0.x, Rails 3.1.0 and Rails 2.3.5.

Note: for Rails 3.0.x, you will probably need to use Smailer 0.5.x, because of a version incompatibility with the `mail` Gem.

It should work with Rails 4 as well, but it hasn't been tested extensively there. Testing and PRs for Rails 4 compatibility are welcome. See [this issue](https://github.com/livebg/smailer/issues/16) for more info.

## Install

### Install the gem

For Rails 3 projects, add the following to your `Gemfile`:

	gem 'smailer'

Then run `bundle install`. For Rails 2.x projects which do not use Bundler, add `config.gem 'smailer'` to your `environment.rb` file and then run `rake gems:install` in your project's root. Also, if you use Rails 2.3.5, you may need to explicitly require a newer version of the `mail` gem, because `mail 2.2.x` has a dependency on ActiveSupport 2.3.6. For example, you can add this to your Rails 2.3.5's `environment.rb`:

	config.gem 'mail', :version => '~> 2.3' # we need 2.3.x which does not depend on ActiveSupport 2.3.6

### Generate and run the migration

To create the tables needed by Smailer to operate, run the `smailer:migration` generator after installing the gem. For Rails 3, you can do this:

	rails g smailer:migration && bundle exec rake db:migrate

For Rails 2.x projects, use `script/generate smailer_migration && rake db:migrate` to generate and run the migration.

### Initializing the plugin's settings

Since the plugin has been designed to be managed via an admin UI, its settings are stored in a simple key-value table, interfaced by the `Smailer::Models::Property` model. Here is some sample data you can use to initialize your settings with:

	Smailer::Models::Property.create! :name => 'queue.max_retries', :value => '0', :notes => '0 = unlimited.'
	Smailer::Models::Property.create! :name => 'queue.max_lifetime', :value => '172800', :notes => 'In seconds; 0 = unlimited.'
	Smailer::Models::Property.create! :name => 'queue.batch_size', :value => '100', :notes => 'Emails to send per run.'
	Smailer::Models::Property.create! :name => 'finished_mails.preserve_body', :value => 'false', :notes => 'If this one is set to true, it will take more space in the DB. Use with caution and for debugging purposes only.'

These properties and values are also the defaults.

## Usage and documentation

Sending out newsletters consists of a couple of steps:

* At least one record should exist in `Smailer::Models::MailingList`. This record can then be used for unsubscribe requests if your system supports multiple newsletter types.
* For each newsletter issue you intend to send, you should create a `Smailer::Models::MailCampaign` record. This record contains the subject and body contents of the newsletter you will be sending out.
* Given a list of active subscribers your application provides, you then enqueue mails to be send via the `MailCampaign#queued_mails` list (see the example below).
* Finally, you should call `Smailer::Tasks::Send.execute` repeatedly to process and send-out the enqueued emails, probably via a Cron daemon.

### Issuing a newsletter

Here is an example how you could proceed with creating and issuing a newsletter:

	# locate the mailing list we'll be sending to
	list = Smailer::Models::MailingList.first

	# create a corresponding mail campaign
	campaign_params = {
		:from      => 'noreply@example.org',
		:subject   => 'My First Campaign!',
		:body_html => '<h1>Hello</h1><p>World</p>',
		:body_text => 'Hello, world!',
		:mailing_list_id => list.id,
	}
	campaign = Smailer::Models::MailCampaign.new campaign_params
	campaign.add_unsubscribe_method :all
	campaign.save!

	# Add attachments
	campaign.add_attachment 'attachment.pdf', 'url_or_file_path_to_attachment'

	# enqueue mails to be sent out
	subscribers = %w[
		subscriber@domain.com
		office@company.com
		contact@store.com
	]
	subscribers.each do |subscriber|
	  campaign.queued_mails.create! :to => subscriber
	end

### Attachments

You can have zero or more attachments to any mail campaign. As demonstrated in the example above, you add them to the campain using the `MailCampaign#add_attachment(file_name, url_or_path)` method.

Any attached files will be referenced at the moment of sending and must be reachable and readable by the send task. Currently, `open-uri` is used to fetch the content of the path or URI. The maximum length of the path/URI field is 2048 symbols.

### Managing unsubscriptions

Among the few unsubscription methods supported, probably the most widely used one is unsubscription via a unsubscribe link in the email.

In order to help you with implementing it, Smailer provides you with some interpolations you can use in the email's body:

* `%{email}` -- the concrete email this message will be sent to (example: `someone@company.com`)
* `%{escaped_email}` -- the same as `%{email}`, but safe to be put within an HTML-version of the message
* `%{email_key}` -- a unique key identifying the %{email} field (example: `34d9ddf91edb4d0206837b125f4a2750`)
* `%{mail_campaign_id}` -- the ID of the `Smailer::Models::MailCampaign` record for this message
* `%{mailing_list_id}` -- the ID of the `Smailer::Models::MailingList` record this mail campaign is for
* `%{message_key}` -- a unique key, identifying the message to be sent out; this key can later be used for view statistics tracking and bounce email processing

Here is an example text you could include in the HTML version of your email to show a unsubscribe link (this also demonstrates how interpolation in the email's body works):

	<p>If you wish to be removed from our mailinglist go here: <a href="http://yourcomain.com/unsubscribe/%{email_key}">http://yourcomain.com/unsubscribe/%{email_key}</a>.</p>
	<p>You are subscribed to the list with the following email address: %{escaped_email}</p>

In this case, you will have to add a route in your Rails app to handle URLs like `'/unsubscribe/:email_key'`. For example, it could lead to `UnsubscribeController#unsubscribe`, which you could implement like so:

	@email = Smailer::Models::MailKey.find_by_key(params[:email_key]).try(:email)
	raise ActiveRecord::RecordNotFound unless @email

	# here you have the @email address of the user who wishes to unsubscribe
	# and can mark it in your system accordingly (or remove it from your lists altogether)

### Sending mails

The emails which have already been placed in the send queue, have to be sent out at some point. This can be done for example with a Rake task which is run periodically via a Cron daemon. Here's an example Rake task you could use:

	# lib/tasks/smailer.rake
	namespace :smailer do
	  desc 'Send out a batch of queued emails.'
	  task :send_batch => :environment do
	    result = Smailer::Tasks::Send.execute :return_path_domain => 'bounces.mydomain.com', :verp => true
	    result.each do |queue_item, status|
	      puts "Sending #{queue_item.to}: #{status}"
	    end
	  end
	end

This task can be executed via `RAILS_ENV=production bundle exec rake smailer:send_batch` (provided you are running it on your production servers).

Notice that we pass a `:return_path_domain` option to `Send.execute`. This domain will be used to construct a dynamic `Return-Path:` address, which you could later use in order to process bounced mails and connect the bounce with a concrete mail campaign and sender's email address. The generated return path will have the following format: `"bounces-SOMEKEY@bounces.mydomain.com"`, where `SOMEKEY` will be the same as the `key` field in the corresponding `FinishedMail` record and will uniquely identify this record, and `bounces.mydomain.com` is what you passed to `:return_path_domain`.

Dynamic return path is generated only when `:return_path_domain` is specified and `:verp` is not false. If you omit the `:verp` option and just pass `:return_path_domain`, `Send.execute` will still use [VERP](http://en.wikipedia.org/wiki/Variable_envelope_return_path) and generate dynamic return path addresses.

### Processing bounces and auto-unsubscribing bad emails

If you use the [VERP support](http://en.wikipedia.org/wiki/Variable_envelope_return_path) Smailer provides when sending your messages, you can easily implement auto-unsubscribe for invalid email addressess or for addresses which bounce too much.

This can be done via a simple cron task, which runs daily (or whatever) on your servers.

Suppose you manage your site's newsletter subscriptions via a `Subscription` model, which has two boolean flags -- `subscribed` and `confirmed` and also an `email` field. You could implement a simple Rake task to be run via a cron daemon this way:

	task :process_bounces => :environment do
	  subscribed_checker = lambda do |recipient|
	    Subscription.confirmed.subscribed.where(:email => recipient).first.present?
	  end

	  Smailer::Tasks::ProcessBounces.execute({
	    :server             => 'bounces.mydomain.com',
	    :username           => 'no-reply@bounces.mydomain.com',
	    :password           => 'mailbox-password',
	    :subscribed_checker => subscribed_checker,
	  }) do |unsubscribe_details|
	    subscription = Subscription.confirmed.subscribed.where(:email => unsubscribe_details[:recipient]).first

	    if subscription
	      subscription.subscribed = false
	      subscription.unsubscribe_reason = 'Automatic, due to bounces'
	      subscription.save!
	    end
	  end
	end

For more info and also if you'd like to adjust the unsubscribe rules, take a look at the `ProcessBounces.execute` method and its options. It's located in `lib/smailer/tasks/process_bounces.rb`. A few extra options are available, such as `:logger` callbacks (which defaults to `puts`), default action for unprocessed bounces, etc.

## TODO

* Tests, tests, tests

## Contribution

Patches are always welcome. In case you find any issues with this code, please use the project's [Issues](http://github.com/mitio/smailer/issues) page on Github to report them. Feel free to contribute! :)

## License

Released under the MIT license.
