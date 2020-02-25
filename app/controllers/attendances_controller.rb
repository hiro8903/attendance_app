class AttendancesController < ApplicationController
  include AttendancesHelper
  before_action :set_user, only: [:edit]
  before_action :logged_in_user, only: [:update, :edit, :edit_overtime_request, :update_overtime_request]
  before_action :admin_or_correct_user, only: [:edit, :update , :edit_overtime_request]
  before_action :set_one_month, only: [:edit]
  before_action :request_states, only: [:edit_overtime_request] # 試しにやったらうまく行ったのであとで正しいアクションを指定する
  
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。"
  
  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    if @attendance.started_at.nil? # 出勤時間が未登録の場合。
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    else @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
    
  end
  
  def edit
  end


  def update_one_month
    if attendances_update_only_one_side?
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        attendances_params.each do |id, item|
          @attendance = Attendance.find(id)
          @attendance.update_attributes!(item) # update_attributes  → falseを返す update_attributes! → 例外を投げる
        end
        flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
        redirect_to user_url(date: params[:date])
      end
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
      flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
        if @attendance.errors.any?
          @attendance.errors.full_messages.each do |msg| 
          flash[:danger] = "#{msg}"
          end 
        end
      redirect_to attendances_edit_user_url(date: params[:date])
  end
  
  def edit_overtime_request
    @user = User.find(params[:user_id])
    @superiors = User.where(superior: true)
    @attendance = Attendance.find(params[:id])
  end
    
  def update_overtime_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    if @attendance.update_attributes!(request_params)
      @attendance.update_attributes(overtime_request_state: "申請中")
      flash[:success] = "残業申請しました。"
      redirect_to @user
    else
      flash[:info] = "無効な入力データがあった為、申請をキャンセルしました。"
      redirect_to @user  
    end
  end
  

  
   private
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end
    
    def request_params
       params.require(:attendance).permit(:overtime_requested_at, :next_day, :reason, :overtime_request_destination, :overtime_request_state)
    end

    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "権限がありません。"
        redirect_to(root_url)
      end  
    end
end
