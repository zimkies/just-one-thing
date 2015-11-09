class TasksController < ApplicationController
  def index
    @user = User.with_short_guid(params[:user_id]).first!
    @tasks = @user.tasks.order(created_at: :desc).all
  end
end
