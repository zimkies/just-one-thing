class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end

  def new
  end

  def create
    user = User.new(user_params)
    if user.save
      flash[:warning] = "Sweet. I've told Jane to text you and get you set up!"
      send_welcome_message(user)
      redirect_to user_path(user)
    else
      flash[:warning] = user.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  private

  def client
    @client ||= Twilio::REST::Client.new
  end

  def send_welcome_message(user)
    client.messages.create(
      from: ENV.fetch('TWILIO_CX_NUMBER'),
      to: user.phone_number,
      body: "Hey there #{user.name}. I just wanted to introduce myself. I'm Jane (from just-one-thing), and together we are going to rock your personal life!"
    )

    sleep(1.0)

    if user.time_zone.now < user.time_zone.now.noon
      client.messages.create(
        from: ENV.fetch('TWILIO_CX_NUMBER'),
        to: user.phone_number,
        body: "As a primer for what's to come, let me know one small personal thing you want to accomplish today. It could be anything from 'Call Mom', to 'pay my electric bill.'"
      )
    else
      client.messages.create(
        from: ENV.fetch('TWILIO_CX_NUMBER'),
        to: user.phone_number,
        body: "For now, just relax :) Get a solid night's sleep tonight, and tomorrow we'll begin!"
      )
    end
  end

  def user_params
    params.require(:user).permit(:name, :phone_number)
  end
end
