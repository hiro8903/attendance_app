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
  
  # 時間外時間の計算
  def on_the_day(user, attendance)
    format("%.2f", (((attendance.overtime_requested_at - user.designated_work_end_time) / 60) / 60.0))
  end
  
  def next_day(user, attendance)
    format("%.2f", (((attendance.overtime_requested_at - user.designated_work_end_time) / 60) / 60.0) + 24)
  end
  


end
