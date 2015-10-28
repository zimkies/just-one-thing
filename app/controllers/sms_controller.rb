class SmsController < ActionController::Base
  UnauthorizedRequest = Class.new(RuntimeError)

  before_filter :check_twilio_sid

  # POST /sms/inbound/
  def inbound
    ticket = ProcessInboundSmsWorker.new.perform(to, from, body)
    render xml: Twilio::TwiML::Response.new.text
  end

  private

  def check_twilio_sid
    if params[:AccountSid] != ENV.fetch('TWILIO_ACCOUNT_SID')
      raise UnauthorizedRequest.new("'#{params[:AccountSid]}' is not a valid Twilio Sid")
    end
  end

  def to
    params[:To]
  end

  def from
    params[:From]
  end

  def body
    params[:Body]
  end
end
