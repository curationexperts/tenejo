class AddIdentifiersToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :identifiers, :string, array: true, default: []
  end
end
