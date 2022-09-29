class AddHeroDescriptionToThemes < ActiveRecord::Migration[5.2]
  def change
    add_column :themes, :hero_description, :string
    add_column :themes, :preview_hero_description, :string
  end
end
