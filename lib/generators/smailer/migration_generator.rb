require "rails/generators/active_record"
require 'smailer'

module Smailer
  class MigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    unless Smailer::Compatibility.rails_4?
      extend ActiveRecord::Generators::Migration
    end

    desc "Create a migration file with definitions of the tables needed to run Smailer."
    source_root File.expand_path('../templates', __FILE__)

    def self.next_migration_number(path)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end

    def generate_migration
      file_name       = 'create_smailer_tables'

      migration_template 'migration.rb.erb', "db/migrate/#{file_name}.rb"
    end
  end
end
