class Task < ActiveRecord::Base
  belongs_to :user

  validates :user_id, :description, presence: true
  validates :completed, inclusion: [true, false]

  scope :today,  -> (time_zone=Time.zone) {
    where(created_at: time_zone.now.midnight..time_zone.now.midnight + 24.hours - 1.second)
  }
end
