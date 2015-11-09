class AddLastWeeklyReminderAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_weekly_reminder_at, :datetime
  end
end
