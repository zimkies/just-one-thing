require './config/boot'
require './config/environment'
require 'clockwork'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  # handler receives the time when job is prepared to run in the 2nd argument
  handler do |job, time|
    puts "Running #{job}, at #{time}"
  end

  every(1.hour, 'task_reminder_worker') { TaskReminderWorker.perform_async }
end
