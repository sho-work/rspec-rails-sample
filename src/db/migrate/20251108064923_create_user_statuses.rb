class CreateUserStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :user_statuses do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.integer :status, null: false, default: 0
      t.text :reason
      t.references :changed_by_user, foreign_key: { to_table: :users }, null: true
      t.datetime :effective_at, null: false

      t.datetime :created_at, null: false
    end

    add_index :user_statuses, [:user_id, :effective_at]
    add_index :user_statuses, :user_id
  end
end
