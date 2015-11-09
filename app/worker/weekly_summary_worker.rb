class WeeklySummaryWorker
  include Sidekiq::Worker

  def perform
    users.each { |user| send_summary(user) }
  end

  private

  def send_summary(user)
    p "sending summary to #{user.to_s}"
    WeeklySummary.new(user).notify
  rescue => e
    p "error: #{e}"
    Rollbar.warn(e)
  end

  def users
    @users ||= User.all.select do |u|
      u.last_weekly_reminder_at.nil? || (u.last_weekly_reminder_at < 1.day.ago)
    end
  end
end

class WeeklySummary
  attr_reader :user

  def initialize(user)
    @user ||= user
  end

  def notify
    user.update_attributes!(last_weekly_reminder_at: Time.zone.now)
    client.messages.create(
      from: ENV.fetch('TWILIO_CX_NUMBER'),
      to: phone_number,
      body: "#{first_name}. Nice work last week - you completed #{completed_count} #{'goal'.pluralize(completed_count)} out of #{total_count} last week. Check them out here: #{tasks_page}"
    )
  end

  private

  delegate :first_name, :phone_number, to: :user

  def tasks_page
    "https://just-one-thing.herokuapp.com/users/#{user.id}/tasks"
  end

  def completed_count
    tasks.where(completed: true).count
  end

  def tasks
    @tasks ||= user.tasks.order(:created_at, :desc)
      .where("created_at > ?", 3.days.ago.beginning_of_week )
  end

  def total_count
    tasks.count
  end

  def client
    @client ||= Twilio::REST::Client.new
  end
end
