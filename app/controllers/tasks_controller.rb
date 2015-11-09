class TasksController < ApplicationController
  def index
    @user = User.find(params[:user_id])
    @tasks = @user.tasks.order(created_at: :desc).where("created_at > ?", 3.days.ago.beginning_of_week).all
  end

  private
end
