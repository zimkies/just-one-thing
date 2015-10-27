class User < ActiveRecord::Base
  validates :name, :phone_number, presence: :true
  validates_uniqueness_of :phone_number

  has_many :tasks

  delegate :midnight, to: "Time.zone.now"

  def todays_task
    tasks.order(:created_at).where("created_at > ?", midnight).last
  end

  def phone_number=(phone_number)
    write_attribute(:phone_number, PhoneNumber.new(phone_number).to_s)
  end

  def time_zone
    Time.zone
  end
end
