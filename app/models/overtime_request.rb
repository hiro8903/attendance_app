class OvertimeRequest < ApplicationRecord
  belongs_to :attendance
  belongs_to :user
  
  enum states:[:none, :applying, :approval, :Denial] # 0:なし、1:申請中、2:承認、3:否認
  
end
