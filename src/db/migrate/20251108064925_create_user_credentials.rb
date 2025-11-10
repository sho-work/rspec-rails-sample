class CreateUserCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :user_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :email, null: false
      t.string :password_digest, null: false
      t.integer :failed_login_attempts, default: 0
      t.datetime :locked_until
      t.datetime :last_login_at

      t.timestamps
    end

    add_index :user_credentials, :email, unique: true
  end
end
