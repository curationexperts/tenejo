class AddParentJobRefToJobs < ActiveRecord::Migration[5.2]
  def change
    add_reference :jobs, :parent_job, foreign_key: { to_table: :jobs }
  end
end
