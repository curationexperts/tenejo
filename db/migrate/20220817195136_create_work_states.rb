class CreateWorkStates < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :graph, :jsonb
  end
end
