class ProcessInboundSmsWorker
  include Sidekiq::Worker

  def perform(to, from, body)
    @to = to
    @from = from
    @body = body

    if body.blank?
      exception = "Ignoring empty text message (to: #{to}, from: #{from})"
      return Rollbar.warning RuntimeError.new(exception)
    end

    p "user.nil? #{user.nil?}"
    p "responding_to_completion_text? #{responding_to_completion_text?}"
    p "responding_to_add_text? #{responding_to_add_text?}"
    p "responding_to_reminder_time_text? #{responding_to_reminder_time_text?}"

    if user.nil?
      forward_sms
    elsif responding_to_completion_text?
      if body.strip.downcase =~ /yes/
        todays_task.update_attributes!(completed: true)
        client.messages.create(
          from: ENV.fetch('TWILIO_CX_NUMBER'),
          to: from,
          body: "Great job! Proud of ya <3"
        )
      else
        client.messages.create(
          from: ENV.fetch('TWILIO_CX_NUMBER'),
          to: from,
          body: still_not_completed_texts.sample
        )
        forward_sms
      end
    elsif responding_to_add_text?
      user.tasks.create!(description: body, completed: false)
      client.messages.create(
        from: ENV.fetch('TWILIO_CX_NUMBER'),
        to: from,
        body: "Great! I'll check in on you after #{user.complete_task_reminder_time}. Text me back different time if it's too early/late."
      )
    elsif responding_to_reminder_time_text?
      time = (body.strip.to_i % 12) + 12
      if user.update_attributes(complete_task_reminder_hour: (body.strip.to_i % 12) + 12, reminder_hour_updated_at: Time.zone.now)
        client.messages.create(
          from: ENV.fetch('TWILIO_CX_NUMBER'),
          to: from,
          body: "Cool! I've updated your reminder texts to start at #{user.complete_task_reminder_time}."
        )
      else
        client.messages.create(
          from: ENV.fetch('TWILIO_CX_NUMBER'),
          to: from,
          body: "#{body.strip} is not a valid time :( Please tell me what hour you want me to remind you. eg 9pm. Or 21:00"
        )
      end
    else
      # Forward SMS to me
      forward_sms
    end
  end

  private

  def still_not_completed_texts
    [
      "Not yet? OK, please try and get it done, I'll check in on ya later.",
      "Still haven't done it? OK I'll keep checking in on ya.",
      "I'm rooting for ya! I think you can do it - I'll check in on ya later",
    ]
  end

  attr_reader :to, :from, :body
  delegate :last_add_reminder_at, :last_complete_reminder_at, :todays_task,
    to: :user

  def forward_sms
    client.messages.create(
      from: ENV.fetch('TWILIO_CX_NUMBER'),
      to: "+18572410267",
      body: "JOT: from #{from}: #{body}"
    )
  end

  def responding_to_completion_text?
    # Last text message (today) is completion text && they haven't responded to it
    last_outbound_message[0] == :complete &&
    last_outbound_message[1].today? &&
    user.todays_task.incomplete?
  end

  def responding_to_reminder_time_text?
    # Last text message (today) is add text && task has been created
    last_outbound_message[0] == :add &&
    last_outbound_message[1].today? &&
    !user.reminder_hour_updated_at.try(:today?) &&
    user.todays_task.present?
  end

  def responding_to_add_text?
    # last text message (today) is add text && they haven't created a task today
    last_outbound_message[0] == :add &&
    last_outbound_message[1].today? &&
    todays_task.nil?
  end

  def last_outbound_message
    if last_add_reminder_at.nil?
      if last_complete_reminder_at.nil?
        [nil, nil]
      elsif last_complete_reminder_at.present?
        [:complete, last_complete_reminder_at]
      end
    else
      if last_complete_reminder_at.nil?
        [:add, last_add_reminder_at]
      elsif last_complete_reminder_at > last_add_reminder_at
        [:complete, last_complete_reminder_at]
      else
        [:add, last_add_reminder_at]
      end
    end
  end

  def user
    @user ||= User.find_by_phone_number(PhoneNumber.new(from).to_s)
  end

  def client
    @client ||= Twilio::REST::Client.new
  end
end
