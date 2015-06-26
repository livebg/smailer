## Version v0.8.0

- Adds support for one-off emails to be send via the same queueing mechanism.
- It is now possible to disable the uniqueness validation for a single email
  per recipient per campaign by passing `:require_uniqueness => false` when
  creating a `QueuedMail` record.

**Possible breaking changes:**

- The `MailCampaignAttachment` chass is now called `MailAttachment`.
- The interface to add an attachment has changed.

    Attachments are no longer saved by `add_attachment`. You have to call
    `Smailer::Models::MailCampaign#save` or `Smailer::Models::MailQueue#save`
    (if it is one-off email).

- There have been changes to the database structure.
- The message key stored in `QueuedMail#key` is no longer generated based only
  on predictable input. Now a `SecureRandom`-generated value is alos used.

**Upgrading from v0.7.3 to v0.8.0**

To make the required changes in the database, you can use this
[smailer_v0_7_3_to_v0_8_0 migration](upgrading/migrations/smailer_v0_7_3_to_v0_8_0.rb).

## Version v0.7.8 (Feb 11 2015)

Make sure QueuedMail is deleted

## Version v0.7.7 (Feb 9 2015)

Fix Rails 2.x compatibility

## Version v0.7.5 (Dec 20 2014)

Fix send task when no mail config is present

## Version v0.7.4 (Dec 20 2014)

Fix SMTP support for Rails 2.x

## Version v0.7.3 (Dec 19 2014)

Add back accidentally reverted changes

## Version v0.7.2 (Dec 19 2014)

Fix mass adding/removing of unsubscribe methods

## Version v0.7.1 (Dec 1 2014)

SQL performance improvements

## Version v0.7.0 (Mar 23 2014)

Attachments support

## Version v0.6.3 (Mar 22 2014)

Rails 4 compatibility

## Version 0.6.2 (Dec 13, 2012)

Delivery methods with options now work

## Version 0.6.1 (Jan 17, 2012)

Don't use meta_where

## Version 0.6.0 (Nov 29, 2011)

Don't keep the body in finished emails

## Version 0.5.4 (Oct 28, 2011)

Use mail 2.3+

## Version 0.5.3 (Oct 27, 2011)

Fixes a syntax error

## Version 0.5.2 (Oct 27, 2011)

Rails 2.3 compatibility for the bounce processor

## Version 0.5.1 (Oct 27, 2011)

Fix in the process bounces task

## Version 0.5.0 (Oct 27, 2011)

Bounce processing task

## Version 0.4.4 (Oct 15, 2011)

Destroy finished mails when a campaign is deleted.

Addresses a potential issue with marking a finished mail as "opened", when the associated mail campaign has been deleted. Adds MAJOR, MINOR and PATCH version constants.

## Version 0.4.3 (Oct 6, 2011)

Fix potential exception in QueuedMail#interpolate

## Version 0.4.2 (Sep 28, 2011)

We don't require mail 2.3+ anymore, 2.2+ will do.

## Version 0.4.1 (Sep 28, 2011)

Needs mail 2.3+ to avoid ActiveSupport dependency.

## Version 0.4.0 (Sep 27, 2011)

Basic VERP-support.

This version bump is due to improper previous version numbering - when new features were introduced, only the PATCH-level version number was increased.

## Version 0.3.2 (Sep 27, 2011)

Runtime requirements fix.

## Version 0.3.1 (Sep 27, 2011)

Fix gem dependencies.

## Version 0.3.0 (Sep 21, 2011)

Queue locking and basic VERP support.

## Version 0.2.16 (Sep 16, 2011)

Rails 2 compatibility mode fixes.

## Version 0.2.15 (Sep 16, 2011)

Fix syntax error in Tasks::Send.

## Version 0.2.14 (Sep 16, 2011)

More on Rails 2 compatibility in Tasks::Send.

## Version 0.2.13 (Sep 16, 2011)

Rails 2 compatibility in Tasks::Send.

## Version 0.2.12 (Sep 16, 2011)

Length validation fixes in QueuedMail and FinishedMail.

## Version 0.2.11 (Sep 13, 2011)

Settings' defaults.

## Version 0.2.10 (Sep 13, 2011)

Fix generated migration in Rails 2 projects.

## Version 2.8.9 (Sep 13, 2011)

duplicate the migration template file for Rails 2 compatibility.

## Version 0.2.8 (Sep 13, 2011)

Rails 2 migration generator template paths fix.

## Version 0.2.7 (Sep 13, 2011)

Rails 2 migration generator fix + USAGE file. (Remove desc method from the definition of the generator, as Rails 2 does not provide such a method.)

## Version 0.2.6 (Sep 13, 2011)

Fix typo in Rails 2 migration generator and update the readme.

## Version 0.2.5 (Sep 13, 2011)

Fix mistyped Rails 2 generator filename.

## Version 0.2.4 (Sep 13, 2011)

Attempt to fix Rails 2 migration generator.

## Version 0.2.3 (Sep 13, 2011)

Working Rails 3 migration generator.

## Version 0.2.2 (Sep 13, 2011)

Working generator for Rails 2 and 3.

## Version 0.2.1 (Sep 13, 2011)

Migration generator.

## Version 0.2.0 (Sep 2, 2011)

Hit counting in MailCampaign and delivery reports for FinishedMail.

## Version bump to 0.1.0 (Sep 2, 2011)

Initial release.
