require 'rails/generators/active_record'

class SmailerMigrationGenerator < ActiveRecord::Generators::Base
  desc "This generator creates a migration file containing definitions of the tables needed to run Smailer."

  def self.source_root
    @source_root ||= File.expand_path('../templates', __FILE__)
  end

  def generate_migration
    file_name       = 'create_smailer_tables'
    @migration_name = file_name.camelize

    migration_template 'migration.rb.erb', "db/migrate/#{file_name}.rb"
  end
end
