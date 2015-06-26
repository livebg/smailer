source :rubygems

# Specify your gem's dependencies in smailer.gemspec
gemspec

gem "rails", ">= 3.0.0"

group :development, :test do
  gem 'sqlite3'

  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-rails'
end

group :test do
  gem 'spork'

  gem 'rspec'
  gem 'rspec-rails'

  gem 'factory_girl'

  gem 'shoulda-matchers'
  gem 'database_cleaner'
end
