class RemoveSiteDescriptionFromThemes < ActiveRecord::Migration[5.2]
  def change
    remove_column :themes, :site_description, :string
    remove_column :themes, :preview_site_description, :string
  end
end
