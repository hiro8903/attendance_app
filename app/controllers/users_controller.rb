class UsersController < ApplicationController
  before_action :set_user, only: [:show, :confirm_application, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :show_one_week, :edit_overtime_reception, :update_overtime_reception, :edit_change_reception]
  before_action :logged_in_user, only: [:show, :index, :edit, :update, :destroy, :show_one_week]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:destroy, :edit_basic_info, :update_basic_info, :index]
  before_action :admin_or_correct_user, only: [:edit]
  before_action :sperior_or_correct_user, only: [:show]
  before_action :set_one_month, only: [:show, :confirm_application, :show_one_week]
  before_action :set_one_week , only: :show_one_week
  
  def index
 
    #キーワードが入力されていれば、whereメソッドとLIKE検索（部分一致検索）を組み合わせて、必要な情報のみ取得する。
    if params[:user_search]
      @users = User.where('name LIKE ?', "%#{params[:user_search]}%").paginate(page: params[:page])
      @page_title ="検索結果"
    else
      @users = User.paginate(page: params[:page])
      @page_title ="ユーザー一覧"
    end
    
  end

  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
    @superiors = User.where(superior: true)
    @attendance = Attendance.find(params[:id])
    @overtime_requests = Attendance.where(overtime_request_destination: @user.name, overtime_request_state: "申請中")
    @change_requests = Attendance.where(change_request_destination: @user.id, change_request_state: 2)
  end
  
  def show_one_week
    @worked_sum = @attendances_of_week.where.not(started_at: nil).count
  end

  def confirm_application
    @worked_sum = @attendances.where.not(started_at: nil).count
    @superiors = User.where(superior: true)
    @attendance = Attendance.find(params[:id])
    @overtime_requests = Attendance.where(overtime_request_destination: @user.name, overtime_request_state: "申請中")
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user # 保存成功後、ログインする。
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_all_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      render :edit      
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end
  
  def edit_basic_info
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
      redirect_to @user and return
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url and return
  end
  
  def edit_overtime_reception
    @overtime_requests = Attendance.where(overtime_request_destination: @user.name, overtime_request_state: "申請中") 
    @applying_users = User.joins(:attendances).merge(Attendance.where(overtime_request_destination: @user.name, overtime_request_state: "申請中") ).uniq
  end
  

  def update_overtime_reception
    if overtime_reception_params.each do |id, item|
      attendance = Attendance.find(id)
     attendance.update_attributes(item) # update_attributes  → falseを返す update_attributes! → 例外を投げる
      end
      flash[:success] = "残業申請を更新しました。"
      redirect_to user_url and return
    else
      flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
      redirect_to user_url and return
    end
  end
  
  def edit_change_reception
    @change_requests = Attendance.where(change_request_destination: @user.id, change_request_state: 2)
    @change_request_users = User.joins(:attendances).merge(Attendance.where(change_request_destination: @user.id, change_request_state: 2) ).uniq
  end
  
  def update_change_reception
      if change_reception_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.update_attributes(item)# update_attributes  → falseを返す update_attributes! → 例外を投げる
        end
        flash[:success] = "勤怠変更申請を許可しました。"
        redirect_to user_url and return
      
      else
        flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
        redirect_to user_url and return
      end
    
  end
  


# def update_overtime_reception これでも正しく動いた
# ActiveRecord::Base.transaction do # トランザクションを開始します。
#     overtime_reception_params.each do |id, item|
#       attendance = Attendance.find(id)
#       attendance.update_attributes!(item)
#     end
#   end
#   flash[:success] = "残業申請を更新しました。"
#   redirect_to user_url(date: params[:date])
#   rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
#   flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
#   redirect_to user_url(date: params[:date])
#   end

  private

    def user_params
      params.require(:user).permit(:name, :email, :department, :affiliation, :employee_number,
                                    :uid, :password, :password_confirmation)
    end
    
    def basic_info_params
      params.require(:user).permit(:basic_time,:work_time, :basic_work_time, 
                                    :designated_work_start_time, :designated_work_end_time)
    end
    
    def user_all_params
      params.require(:user).permit(:name, :email, :department, :affiliation, :employee_number,
                                    :uid, :password, :password_confirmation, :basic_time,
                                    :work_time, :basic_work_time, 
                                    :designated_work_start_time, :designated_work_end_time)
    end
    
    def overtime_reception_params
      params.require(:user).permit(attendances: [:overtime_request_state, :overtime_change])[:attendances]
    end
    
    def change_reception_params
      params.require(:user).permit(attendances: [:change_request_state, :attendance_change_checkbox])[:attendances]
    end
    
    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "権限がありません。"
        redirect_to(root_url)
      end  
    end
    
    # 上長、または現在ログインしているユーザーを許可します。
    def sperior_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.superior?
        flash[:danger] = "権限がありません。"
        redirect_to(root_url)
      end  
    end
end