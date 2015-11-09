class AddGuidToUsers < ActiveRecord::Migration
  def change
    add_column :users, :guid, :string
    generate_guids
  end

  def generate_guids
    User.all.each do |user|
      user.update_attributes!(guid: SecureRandom.uuid)
    end
  end
end
