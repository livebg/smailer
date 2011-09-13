class SmailerMigrationGenerator < Rails::Generator::Base
  def manifest
    file_name       = 'create_smailer_tables'
    @migration_name = file_name.camelize
    template_path   = File.expand_path('../../lib/generators/smailer/templates/migration.rb.erb', File.dirname(__FILE__))

    record do |m|
      m.migration_template template_path, File.join('db', 'migrate'), :migration_file_name => file_name
    end
  end
end
