class AddOvertimeStatesToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_request_destination, :string
    add_column :attendances, :overtime_request_state, :string
  end
end
