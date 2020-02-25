module AttendancesHelper
  
  def attendance_state(attendance)
    # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    if Date.current == attendance.worked_on
      return '出社' if attendance.started_at.nil?
      return '退社' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    false
  end
  
  # 出勤時間と退勤時間を受け取り、在社時間を計算して返します。
  def working_times(start, finish)
    format("%.2f", (((finish - start) / 60) / 60.0))
  end
  
  # 基準値(15)で割って小数点以下は切り捨て（２dで整数二桁）、15をかける
  # 基準値（今回は15）で割って小数点以下は切り捨て、その数に15をかければ丸めた数を返すことができます。
  # 例えば32÷15は、2.13...なので、小数点以下を切り捨てると2。×15＝30を返すことができます。
  def every_15_minutes(time)
    format("%.2d", (((time.min)/15)*15))
  end
  
  # 総合勤務時間（基本時間　×　出勤日数）
  def basic_times_sum(basic_time, worked_sum)
    format_basic_info(basic_time).to_f * worked_sum
  end
  
  # 出勤時間または退勤時間だけになる編集は無効
  def attendances_update_only_one_side?
    attendances = true
    attendances_params.each do |id, item|
      if item[:started_at].blank? && item[:finished_at].blank?
        next
      elsif item[:started_at].blank? || item[:finished_at].blank?
        attendances = false
        flash[:danger] = "出勤時間または退勤時間だけになる編集はできません。"
        redirect_to attendances_edit_user_url(date: params[:date])
      end
    end
    return attendances
  end
  
  # Datetime型の年月日を1/1/1にして、時分秒を元のままtime型にして戻す
  # Datetimeからtimeのところだけ使って残業時間の差分を計算するため使用する
  def time_only(datetime)
    Time.parse(datetime.strftime("1/1/1 %H:%M:%S"))
  end
  
  
  # 時間外時間の計算
  def overtime_hour(user, attendance)
    if attendance.next_day == false # 当日中に残業終了（翌日のチェックボックスにチェクされていない時）
      format("%.2f", on_the_day(user, attendance))
    else # 翌日に残業終了（翌日のチェックボックスにチェクされている時）
      format("%.2f", next_day(user, attendance))
    end
  end
  
  # 時間外時間の計算のための要素（当日に残業を終えた時の計算）
  def on_the_day(user, attendance)
    # Datetimeからtimeのところだけ計算するため、年月日を統一させている
    request_time = time_only(attendance.overtime_requested_at)
    basic_end_time = time_only(user.designated_work_end_time)
    
    (((request_time - basic_end_time) / 60) / 60.0)
  end
  
  # 時間外時間の計算のための要素（翌日に残業を終えた時の計算）
  def next_day(user, attendance)
    # Datetimeからtimeのところだけ計算するため、年月日を統一させている
    request_time = time_only(attendance.overtime_requested_at)
    basic_end_time = time_only(user.designated_work_end_time)
    
    (((request_time - basic_end_time) / 60) / 60.0) + 24
  end
  

end
