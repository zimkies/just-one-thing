class User < ActiveRecord::Base
  validates :name, :phone_number, presence: :true
  validates_uniqueness_of :phone_number

  has_many :tasks

  def phone_number=(phone_number)
    write_attribute(:phone_number, PhoneNumber.new(phone_number).to_s)
  end

  def time_zone
    Time.zone
  end
end
