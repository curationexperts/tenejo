class CreateThemes < ActiveRecord::Migration[5.2]
  def change
    create_table :themes do |t|
      t.string :site_title
      t.string :primary_color
      t.string :accent_color
      t.string :primary_text_color
      t.string :accent_text_color
      t.string :background_color

      t.timestamps
    end
  end
end
