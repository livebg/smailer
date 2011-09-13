class SmailerMigrationGenerator < Rails::Generators::Base
  desc "This generator creates a migration file containing definitions of the tables needed to run Smailer."

  def create_migration_file
    root        = File.dirname(__FILE__)
    source      = File.expand_path 'templates/migration.rb', root
    destination = Rails.root.join("db/migrate/#{next_migration_number}_create_smailer_tables.rb")

    FileUtils.cp source, destination

    puts "Created #{destination}"
  end

  protected

  def next_migration_number
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end
end