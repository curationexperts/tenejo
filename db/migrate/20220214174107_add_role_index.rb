class AddRoleIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :roles, :name, unique: true
  end
end
