module Smailer
  class MigrationGenerator < Rails::Generators::Base
    desc "Create a migration file with definitions of the tables needed to run Smailer."

    def manifest
      file_name       = 'create_smailer_tables'
      @migration_name = file_name.camelize
      template_path   = File.expand_path('../../lib/generators/smailer/templates/migration.rb.erb', File.dirname(__FILE__))

      record do |m|
        m.migration_template template_path, File.join('db', 'migrate'), :migration_file_name => file_name
      end
    end
  end
end
