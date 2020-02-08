class AddOvertimeRequestedAtToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_requested_at, :datetime
  end
end
