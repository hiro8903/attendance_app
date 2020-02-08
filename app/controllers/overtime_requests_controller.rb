class OvertimeRequestsController < ApplicationController
  include AttendancesHelper
  before_action :set_user, only: [:edit]
  before_action :logged_in_user, only: [:edit]
  before_action :correct_user, only: [:edit]

  def edit
    # @user = User.find(params[:user_id])
    # @attendance = Attendance.find(params[:id])
    @user = User.find(params[:user_id])
  end
  
  def show
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
  end
  
  def edit_user_overtime_request
  end
  
end
