class CreateUserProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :username, null: false
      t.text :bio
      t.string :avatar_url
      t.string :website_url
      t.date :birth_date

      t.timestamps
    end
  end
end
