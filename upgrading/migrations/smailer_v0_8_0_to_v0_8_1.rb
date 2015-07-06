class SmailerV080ToV081 < ActiveRecord::Migration
  def self.up
    add_column :mail_templates, :reply_to, :string
  end

  def self.down
    remove_column :mail_templates, :reply_to
  end
end
