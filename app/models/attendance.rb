class Attendance < ApplicationRecord
  belongs_to :user
  enum change_request_state: { "なし" => 1, "申請中" => 2, "承認" => 3, "否認" => 4 }

  validates :worked_on, presence: true
  validates :note, length: { maximum: 50 }
  validates :instruction, length: { maximum: 50 }
  validates :instructor, length: { maximum: 50 }
  
  # 出勤時間が存在しない場合、退勤時間は無効
  validate :finished_at_is_invalid_without_a_started_at
  # 出勤・退勤時間どちらも存在する時、出勤時間より早い退勤時間は無効
  validate :started_at_than_finished_at_fast_if_invalid
  # 指定勤務終了時間より早い残業終了予定時間は無効 思った通りになっていないのでとりあえずコメントアウト
  # validate :overtime_requested_at_earlier_than_designated_work_end_time_is_invalid
  
  # 残業申請を受け、変更を送信する際にチェックボックスにチェックが無い申請は変更されない
  validates :overtime_change, acceptance: true
  
  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end
  
  def started_at_than_finished_at_fast_if_invalid
    if started_at.present? && finished_at.present?
      errors.add(:started_at, "より早い退勤時間は無効です") if started_at > finished_at
    end
  end
  
  def overtime_requested_at_earlier_than_designated_work_end_time_is_invalid
    if user[:designated_work_end_time] > overtime_requested_at
      errors.add(:designated_work_end_time, "より早い残業終了予定時間は無効です")
    end
  end
end
