class AddPreviewsToThemes < ActiveRecord::Migration[5.2]
  def change
    add_column :themes, :preview_site_title, :string
    add_column :themes, :preview_primary_color, :string
    add_column :themes, :preview_accent_color, :string
    add_column :themes, :preview_primary_text_color, :string
    add_column :themes, :preview_accent_text_color, :string
    add_column :themes, :preview_background_color, :string
  end
end
