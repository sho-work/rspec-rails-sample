class AddUserAndViewCountToBlogs < ActiveRecord::Migration[8.0]
  def change
    add_reference :blogs, :user, null: false, foreign_key: true
    add_column :blogs, :view_count, :integer, default: 0
  end
end
