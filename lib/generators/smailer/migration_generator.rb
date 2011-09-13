require "rails/generators/active_record"

module Smailer
  class MigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    extend ActiveRecord::Generators::Migration

    desc "Create a migration file with definitions of the tables needed to run Smailer."
    source_root File.expand_path('../templates', __FILE__)

    def generate_migration
      file_name       = 'create_smailer_tables'

      migration_template 'migration.rb.erb', "db/migrate/#{file_name}.rb"
    end
  end
end