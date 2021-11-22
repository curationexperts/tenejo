class CreateJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :jobs do |t|
      t.string :type
      t.string :label
      t.references :user, foreign_key: true
      t.string :status
      t.datetime :completed_at
      t.integer :collections
      t.integer :works
      t.integer :files

      t.timestamps
    end
    add_index :jobs, :type
    add_index :jobs, :status
    add_index :jobs, :completed_at
  end
end
