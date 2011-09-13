class SmailerMigrationGenerator < Rails::Generators::Base
  desc "This generator creates a migration file containing definitions of the tables needed to run Smailer."

  def manifest
    file_name       = 'create_smailer_tables'
    @migration_name = file_name.camelize
    template_path   = File.join('../../lib/generators/templates/migration.rb.erb', __FILE__)

    record do |m|
      m.migration_template template_path, File.join('db', 'migrate'), :migration_file_name => file_name
    end
  end
end
