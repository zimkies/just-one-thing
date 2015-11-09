class TaskReminderWorker
  include Sidekiq::Worker

  def perform
    users.each { |user| update_user(user) }
  end

  private

  def update_user(user)
    UserTaskReminder.new(user).call
  rescue => e
    p "error: #{e}"
    Rollbar.warn(e)
  end

  def users
    @users ||= User.all.select do |user|
      user_reminder_type(user).present?
    end
  end

  # :add, :complete, or nil
  def user_reminder_type(user)
    UserTaskReminder.new(user).reminder_type
  end
end

class UserTaskReminder
  ADD_TASK_TEXT_HOUR = 9
  SENDABLE_HOURS = ADD_TASK_TEXT_HOUR..23

  def initialize(user)
    @user = user
  end

  def call
    case reminder_type
    when :add
      send_add_message
    when :complete
      send_complete_message
    end
  end

  def reminder_type
    return unless time_zone.now.hour.in? SENDABLE_HOURS
    return if created_at.today?

    if todays_task.nil?
      return :add
    elsif todays_task.incomplete? && (time_zone.now.hour >= complete_task_reminder_hour)
      return :complete
    end
  end

  private

  attr_reader :user
  delegate :time_zone, :created_at, :todays_task, :last_add_reminder_at,
   :first_name, :phone_number, to: :user

  def client
    @client ||= Twilio::REST::Client.new
  end

  def send_complete_message
    user.update_attributes!(last_complete_reminder_at: Time.zone.now)
    client.messages.create(
      from: ENV.fetch('TWILIO_CX_NUMBER'),
      to: phone_number,
      body: "Hey #{first_name} - have you completed your task (#{todays_task.description})' for today? Let me know! (yes/no)"
    )
  end

  def simple_goals
    ['call mom', 'brush my teeth', 'make my bed']
  end

  def all_goals
    ['cook dinner', 'say hi to an old friend', 'clean my room', 'do my laundry'] + simple_goals
  end

  def first_ever_wake_up_message
    "Rise and shine, #{first_name}! Text me back your single personal goal for today please. It really doesn't have to be big - even as simple as '#{all_goals.sample}'"
  end

  def wake_up_messages
    [
      first_ever_wake_up_message,
      "Good morning, #{first_name}. What personal goal are you going to work on today? How about '#{all_goals.sample}'?",
      "What a beautiful day to get something done for yourself, #{first_name}. What's it going to be today?",
      "Bon jour, #{first_name}. Text me your personal goal for today s'il vous plait!",
      "#{first_name}!!! Need some inspiration for a personal goal today? How about '#{all_goals.sample}'?",
      "Up and at 'em, #{first_name} - Please let me know what you're going to do for your personal life today. It's important!",
      "Roses are red, violets are blue, what in your personal life today, are you to do? :P Let me know",
      "#{first_name}, guess what??? I know you're going to accomplish something great today :) Can you tell me what it is?",
    ]
  end

  def add_rereminder_messages
    [
      "#{first_name}! Why are you ignoring me? Just text me one goal!",
      "Are you mad at me? A quick text message really isn't that hard...",
      "I'm waiting on you, #{first_name}...",
      "OK, I know life is busy, but all I want is a simple goal text from you, #{first_name}. Pleeeaaaase?",
      "^^",
      "I'm not messing around here, #{first_name}. Today's personal goal. NOW!",
      "#{first_name}, do I really have to ask you again? Just one task, that's all I ask.",
      "Do I need to send you a coffee? Pleeeease let me know what you're working on today.",
      "Your goal, #{first_name}, before I resort to sending you cat gifs. I will do it, don't doubt me!!!",
    ]
  end

  def send_add_message
    # First add message ever
    if last_add_reminder_at.nil?
      user.update_attributes!(last_add_reminder_at: Time.zone.now)
      client.messages.create(
        from: ENV.fetch('TWILIO_CX_NUMBER'),
        to: phone_number,
        body: first_ever_wake_up_message
      )

    # already reminded today
    elsif last_add_reminder_at.today?
      user.update_attributes!(last_add_reminder_at: Time.zone.now)
      client.messages.create(
        from: ENV.fetch('TWILIO_CX_NUMBER'),
        to: phone_number,
        body: add_rereminder_messages.sample
      )

    # First reminder today
    else
      user.update_attributes!(last_add_reminder_at: Time.zone.now)
      client.messages.create(
        from: ENV.fetch('TWILIO_CX_NUMBER'),
        to: phone_number,
        body: wake_up_messages.sample
      )
    end
  end
end
