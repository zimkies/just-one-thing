module HasGuid
  SHORT_GUID_LENGTH = 8
  extend ActiveSupport::Concern

  included do
    validates :guid, presence: true

    scope :with_short_guid, -> (guid) {
      return none unless guid.present? && guid.length == SHORT_GUID_LENGTH
      where("#{table_name}.guid LIKE '#{guid}%'")
    }

    before_validation on: :create do
      # This is ||= to allow explicitly setting guids if necessary
      self.guid ||= SecureRandom.uuid
    end

    def short_guid
      guid[0...SHORT_GUID_LENGTH]
    end
  end
end
