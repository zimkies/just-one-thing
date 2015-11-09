class AddCompleteTaskReminderHourToUsers < ActiveRecord::Migration
  def change
    add_column :users, :complete_task_reminder_hour, :integer
  end
end
