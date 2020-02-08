class AddReasonToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :reason, :string
  end
end
