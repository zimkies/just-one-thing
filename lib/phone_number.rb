class PhoneNumber
  delegate :to_s, to: :@number

  def initialize(number, country_code: '1')
    return @number = nil if number.blank?
    temp_number = special_case_us_numbers(number, country_code)
    @number = Phoner::Phone.parse(temp_number, country_code: country_code)
    @number ||= strip_country_code(temp_number, country_code)
  rescue Phoner::PhoneError
    begin
      @number = strip_country_code(temp_number, country_code)
    rescue Phoner::PhoneError
      @number = nil
    end
  end

  private

  # Attempt to remove the country_code in a desperate last-ditch attempt to
  # produce a valid-looking phone number
  def strip_country_code(number, country_code = nil)
    length = country_code.to_s.length
    Phoner::Phone.parse(number[length..-1], country_code: country_code)
  end

  # Very often, we see US numbers with an extra 1, but no "+". Phoner treats
  # these as valid, but we're pretty sure they are not.
  #
  # If we see an 11 digit US number starting with "1", just resturn the last
  # 10 digits
  def special_case_us_numbers(raw_number, country_code)
    return raw_number unless country_code == '1'
    # Strip out non digits otherwise parens break things
    number = raw_number.gsub(/[^\d]/, '')
    (number.length == 11 && number[0] == '1') ? number[1..-1] : raw_number
  end
end
