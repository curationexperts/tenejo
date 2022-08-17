class CreateWorkStates < ActiveRecord::Migration[5.2]
  def change
    create_table :work_states do |t|
      t.integer :row_identifier
      t.string :status
      t.references :job, foreign_key: true
      t.timestamp :finished_at
    end
  end
end
