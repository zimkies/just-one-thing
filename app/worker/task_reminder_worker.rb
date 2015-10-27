class TaskReminderWorker
  include Sidekiq::Worker
  ADD_TASK_TEXT_HOUR = 9
  COMPLETE_TASK_TEXT_HOUR = 19
  SENDABLE_HOURS = ADD_TASK_TEXT_HOUR..23

  def perform
    users.each { |user| update_user(user) }
  end

  private

  def update_user(user)
    case user_reminder_type(user)
    when :add
      send_add_message(user)
    when :complete
      send_complete_message(user)
    end
  rescue => e
    p "error: #{e}"
    Rollbar.warn(e)
  end

  def client
    @client ||= Twilio::REST::Client.new
  end

  def send_complete_message(user)
    user.update_attributes!(last_complete_reminder_at: Time.zone.now)
    client.messages.create(
      from: ENV.fetch('TWILIO_CX_NUMBER'),
      to: user.phone_number,
      body: "Hey #{user.name} - have you completed your task (#{user.todays_task.description})' for today? Let me know! (yes/no)"
    )
  end

  def send_add_message(user)
    user.update_attributes!(last_add_reminder_at: Time.zone.now)
    client.messages.create(
      from: ENV.fetch('TWILIO_CX_NUMBER'),
      to: user.phone_number,
      body: "Rise and shine, #{user.name}! Text me back your single personal goal for today please. It really doesn't have to be big - even as simple as 'clean my room.'"
    )
  end

  def users
    @users ||= User.all.select do |user|
      user_reminder_type(user).present?
    end
  end

  # :add, :complete, or nil
  def user_reminder_type(user)
    return unless user.time_zone.now.hour.in? SENDABLE_HOURS

    if user.todays_task.nil?
      return :add
    elsif user.todays_task.incomplete? && (user.time_zone.now.hour > COMPLETE_TASK_TEXT_HOUR)
      return :complete
    end
  end
end
