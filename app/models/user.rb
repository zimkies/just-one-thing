class User < ActiveRecord::Base
  include HasGuid
  VALID_COMPLETE_TASK_REMINDER_HOURS = 15..23

  validates :name, :phone_number, presence: :true
  validates_inclusion_of :complete_task_reminder_hour, :in => VALID_COMPLETE_TASK_REMINDER_HOURS,
    allow_nil: true
  validates_uniqueness_of :phone_number

  has_many :tasks

  delegate :midnight, to: "Time.zone.now"

  def first_name
    name.split(' ').first
  end

  def todays_task
    tasks.order(:created_at).where("created_at > ?", midnight).last
  end

  def phone_number=(phone_number)
    write_attribute(:phone_number, PhoneNumber.new(phone_number).to_s)
  end

  def time_zone
    Time.zone
  end

  def complete_task_reminder_time
    "#{(complete_task_reminder_hour - 12)}pm"
  end

  def complete_task_reminder_hour
    self[:complete_task_reminder_hour] || 20
  end
end
