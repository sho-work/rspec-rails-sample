# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_08_064934) do
  create_table "blog_tags", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_id", "tag_id"], name: "index_blog_tags_on_blog_id_and_tag_id", unique: true
    t.index ["blog_id"], name: "index_blog_tags_on_blog_id"
    t.index ["tag_id"], name: "index_blog_tags_on_tag_id"
  end

  create_table "blogs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.boolean "published", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "view_count", default: 0
    t.index ["user_id"], name: "index_blogs_on_user_id"
  end

  create_table "tags", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "user_credentials", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "failed_login_attempts", default: 0
    t.datetime "locked_until"
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_user_credentials_on_email", unique: true
    t.index ["user_id"], name: "index_user_credentials_on_user_id"
  end

  create_table "user_profiles", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "username", null: false
    t.text "bio"
    t.string "avatar_url"
    t.string "website_url"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "user_statuses", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.text "reason"
    t.bigint "changed_by_user_id"
    t.datetime "effective_at", null: false
    t.datetime "created_at", null: false
    t.index ["changed_by_user_id"], name: "index_user_statuses_on_changed_by_user_id"
    t.index ["user_id", "effective_at"], name: "index_user_statuses_on_user_id_and_effective_at"
    t.index ["user_id"], name: "index_user_statuses_on_user_id"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "blog_tags", "blogs"
  add_foreign_key "blog_tags", "tags"
  add_foreign_key "blogs", "users"
  add_foreign_key "user_credentials", "users"
  add_foreign_key "user_profiles", "users"
  add_foreign_key "user_statuses", "users"
  add_foreign_key "user_statuses", "users", column: "changed_by_user_id"
end
