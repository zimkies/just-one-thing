class AddReminderHourUpdatedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :reminder_hour_updated_at, :datetime
  end
end
