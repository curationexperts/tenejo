class AddHeroTitleToThemes < ActiveRecord::Migration[5.2]
  def change
    add_column :themes, :hero_title, :string
    add_column :themes, :preview_hero_title, :string
  end
end
