class ProblemReports < ActiveRecord::Migration
  def up
    create_table :problem_reports do |t|
      t.string :exception_message
      t.string :exception_class
      t.text :exception_backtrace
      t.integer :signed_in_user_id
      t.string :status, :default => 'new'
      t.timestamps
    end
  end

  def down
    drop_table :problem_reports
  end
end
