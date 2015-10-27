class AddLastCompleteReminderAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_complete_reminder_at, :datetime
    add_column :users, :last_add_reminder_at, :datetime
  end
end
