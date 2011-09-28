# Simple newsletter mailer for Rails

## Intro

This project is a simple mailer for newsletters, which implements simple queue processing, basic campaign management and has some unsubscribe support.

It is intended to be used within a Rails project. It has been tested with Rails 3.0.x, Rails 3.1.0 and Rails 2.3.5.

## Install

### Install the Gem

For Rails 3 projects, add the following to your `Gemfile`:

	gem 'smailer'

Then run `bundle install`. For Rails 2.x projects which do not use Bundler, add `config.gem 'smailer'` to your `environment.rb` file and then run `rake gems:install` in your project's root. Also, if you use Rails 2.3.5, you may need to explicitly require a newer version of the `mail` gem, because `mail 2.2.x` has a dependency on ActiveSupport 2.3.6. For example, you can add this to your Rails 2.3.5's `environment.rb`: `config.gem 'mail', :version => '~> 2.3' # we need 2.3.x which does not depend on ActiveSupport 2.3.6`

### Generate and run the migration

To create the tables needed by Smailer to operate, run the `smailer:migration` generator after installing the Gem. For Rails 3, you can do this:

	rails g smailer:migration && bundle exec rake db:migrate

For Rails 2.x projects, use `script/generate smailer_migration && rake db:migrate` to generate and run the migration.

### Initializing the plugin's settings

Since the plugin has been designed to be managed via an admin UI, its settings are stored in a simple key-value table, interfaced by the `Smailer::Models::Property` model. Here is some sample data you can use to initialize your settings with:

	Smailer::Models::Property.create! :name => 'queue.max_retries', :value => '0', :notes => '0 = unlimited.'
	Smailer::Models::Property.create! :name => 'queue.max_lifetime', :value => '172800', :notes => 'In seconds; 0 = unlimited.'
	Smailer::Models::Property.create! :name => 'queue.batch_size', :value => '100', :notes => 'Emails to send per run.'

These properties and values are also the defaults.

## Usage and documentation

Sending out newsletters consists of a couple of steps:

* At least one record should exist in `Smailer::Models::MailingList`. This record can then be used for unsubscribe requests if your system supports multiple newsletter types.
* For each newsletter issue you intend to send, you should create a `Smailer::Models::MailCampaign` record. This record contains the subject and body contents of the newsletter you will be sending out.
* Given a list of active subscribers your application provides, you then enqueue mails to be send via the `MailCampaign#queued_mails` list (see the example below).
* Finally, you should call `Smailer::Tasks::Send.execute` repeatedly to process and send-out the enqueued emails.

### Issuing a newsletter

This is an example how you could proceed with creating and issuing a newsletter:

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
	
	# enqueue mails to be sent out
	subscribers = %w[
		subscriber@domain.com
		office@company.com
		contact@store.com
	]
	subscribers.each do |subscriber|
	  campaign.queued_mails.create! :to => subscriber
	end


### Managing unsubscriptions

There are a few unsubscription methods supported. The most common one is probably via a unsubscribe link in the email. 

In order to help you with implementing it, Smailer provides you with some interpolations you can use in the email's body:

* `%{email}` -- the concrete email this message will be sent to (example: `someone@company.com`)
* `%{escaped_email}` -- the same as `%{email}`, but safe to be put within an HTML-version of the message
* `%{email_key}` -- a unique key identifying the %{email} field (example: `34d9ddf91edb4d0206837b125f4a2750`)
* `%{mail_campaign_id}` -- the ID of the `Smailer::Models::MailCampaign` record for this message
* `%{mailing_list_id}` -- the ID of the `Smailer::Models::MailingList` record this mail campaign is for
* `%{message_key}` -- a unique key, identifying the message to be sent out; this key can later be used for view statistics tracking and bounce email processing

Here is an example text you could include in the HTML version of your email to show a unsubscribe link (this also demonstrates how interpolation in the email's body works):

	<p>If you wish to be removed from our mailinglist go here: <a href="http://yourcomain.com/unsubscribe/%{email_key}">http://yourcomain.com/unsubscribe/%{email_key}</a>.</p>
	<p>You are subscribed to the list with the email address: %{escaped_email}</p>

You have to implement a route in your Rails app to handle '/unsubscribe/:email_key'. For example, it could go to `UnsubscribeController#unsubscribe`, which you could implement like so:

	@email = Smailer::Models::MailKey.find_by_key(params[:email_key]).try(:email)
	raise ActiveRecord::RecordNotFound unless @email

	# here you have the @email address of the user who wishes to unsubscribe
	# and can mark it in your system accordingly (or remove it from your lists altogether)

### Sending mails

The emails which have been placed in the queue previously, have to be sent out at some point. This can be done for example with a Rake task which is run periodically via a Cron daemon. Here's an example Rake task:

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

Dynamic return path is generated only when `:return_path_domain` is specified and `:verp` is not false. If you omit the `:verp` option and just pass `:return_path_domain`, `Send.execute` will still use VERP and generate dynamic return path addresses.

## TODO

* Tests, tests, tests

## Contribution

Patches are always welcome. In case you find any issues with this code, please use the project's [Issues](http://github.com/mitio/smailer/issues) page on Github to report them. Feel free to contribute! :)

## License

Released under the MIT license.