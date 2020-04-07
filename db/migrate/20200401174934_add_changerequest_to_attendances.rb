class AddChangerequestToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :change_request_destination, :integer
    add_column :attendances, :change_request_state, :integer
    add_column :attendances, :initial_started_at, :datetime
    add_column :attendances, :initial_finished_at, :datetime
    add_column :attendances, :just_before_started_at, :datetime
    add_column :attendances, :just_before_finished_at, :datetime
  end
end
