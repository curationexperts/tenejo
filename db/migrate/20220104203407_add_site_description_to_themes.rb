class AddSiteDescriptionToThemes < ActiveRecord::Migration[5.2]
  def change
    add_column :themes, :site_description, :string
    add_column :themes, :preview_site_description, :string
  end
end
