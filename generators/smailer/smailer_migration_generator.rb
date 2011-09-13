class SmailerMigrationGenerator < Rails::Generator::Base
  def manifest
    file_name       = 'create_smailer_tables'
    @migration_name = file_name.camelize

    record do |m|
      m.migration_template 'migration.rb.erb', File.join('db', 'migrate'), :migration_file_name => file_name
    end
  end
end
