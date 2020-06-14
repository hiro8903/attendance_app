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
    @superiors = User.where(superior: true)
  end

  def update_one_month
    if attendances_update_only_one_side? # 出勤時間または退勤時間だけになる編集は無効
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        attendances_params.each do |id, item|
          @attendance = Attendance.find(id)
            # if @attendance.change_request_destination.present?
              @attendance.update_attributes!(initial_started_at: "#{@attendance.started_at}") if (@attendance.just_before_started_at == nil)
              @attendance.update_attributes!(initial_finished_at: "#{@attendance.finished_at}") if (@attendance.just_before_finished_at == nil)
              @attendance.update_attributes!(just_before_started_at: "#{@attendance.started_at}", just_before_finished_at: "#{@attendance.finished_at}")
              @attendance.update_attributes!(item)  # if @attendance.change_request_destination.present? # update_attributes  → falseを返す update_attributes! → 例外を投げる
              @attendance.update_attributes!(change_request_state: 2) if @attendance.change_request_destination.present?
            # end
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

# ちゃんと動くので上記がダメなら下記に戻す
  # def update_one_month
  #   if attendances_update_only_one_side?
  #     ActiveRecord::Base.transaction do # トランザクションを開始します。
  #       attendances_params.each do |id, item|
  #         @attendance = Attendance.find(id)
  #         @attendance.update_attributes!(item) # update_attributes  → falseを返す update_attributes! → 例外を投げる
  #       end
  #       flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
  #       redirect_to user_url(date: params[:date])
  #     end
  #   end
  # rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
  #     flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
  #       if @attendance.errors.any?
  #         @attendance.errors.full_messages.each do |msg| 
  #         flash[:danger] = "#{msg}"
  #         end 
  #       end
  #     redirect_to attendances_edit_user_url(date: params[:date])
  # end


# ちゃんと動くやつなので上のやつがダメになったら下記に戻す
  # def update_one_month
  #   if attendances_update_only_one_side?
  #     ActiveRecord::Base.transaction do # トランザクションを開始します。
  #       attendances_params.each do |id, item|
  #         @attendance = Attendance.find(id)
  #         @attendance.update_attributes!(item) # update_attributes  → falseを返す update_attributes! → 例外を投げる
  #       end
  #       flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
  #       redirect_to user_url(date: params[:date])
  #     end
  #   end
  # rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
  #     flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
  #       if @attendance.errors.any?
  #         @attendance.errors.full_messages.each do |msg| 
  #         flash[:danger] = "#{msg}"
  #         end 
  #       end
  #     redirect_to attendances_edit_user_url(date: params[:date])
  # end
  
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
    # def attendances_params
    #   params.require(:user).permit(attendances: [:started_at, :finished_at, :note],
    #                                 change_attendances: [:id, :attendance_id, :user_id, :request_state, :original_started_at,
    #                                                           :original_finished_at, :change_started_at, :change_finished_at],
    #                                                           )[:attendances]
    # end
    
    #     # 1ヶ月分の勤怠情報を扱います。 ちゃんと動くので上がダメなら下記に戻す
    # def attendances_params
    #   params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    # end
    
        # 1ヶ月分の勤怠情報を扱います。 ちゃんと動くので下がダメなら上記に戻す
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note, :change_request_destination, :change_request_state])[:attendances]
    end

    def request_params
      params.require(:attendance).permit(:overtime_requested_at, :next_day, :reason, :overtime_request_destination, :overtime_request_state,
                                         :change_request_destination, :change_request_state, :request_started_at, :request_finished_at, :approved_started_at, :approved_finished_at)
    end

    # def request_params
    #   params.require(:attendance).permit(:overtime_requested_at, :next_day, :reason, :overtime_request_destination, :overtime_request_state,
    #                                       change_attendances: [:id, :attendance_id, :user_id, :request_state, :original_started_at,
    #                                                           :original_finished_at, :change_started_at, :change_finished_at])
    # end
    
    def change_request_params
      params.require(:change_attendance).permit(:attendance_id, :user_id, :request_state,
                                                :original_started_at, :original_finished_at,
                                                :change_started_at, :change_finished_at)
                                                
                                                
                #                                 name: "Foo Bar", email: "foo@invalid",
                # password: "foo", password_confirmation: "bar"
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
