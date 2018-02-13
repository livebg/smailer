class SmailerV083ToV084 < ActiveRecord::Migration
  def self.up
    add_column :queued_mails, :defer_to, :datetime
    add_column :queued_mails, :locked_key, :string
  end

  def self.down
    remove_column :defer_to, :locked_key
    remove_column :queued_mails, :locked_key
  end
end
