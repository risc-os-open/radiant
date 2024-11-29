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

ActiveRecord::Schema[7.2].define(version: 2009_10_03_095744) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "config", id: :serial, force: :cascade do |t|
    t.string "key", limit: 40, default: "", null: false
    t.text "value", default: ""
    t.index ["key"], name: "key", unique: true
  end

  create_table "extension_meta", id: :serial, force: :cascade do |t|
    t.text "name"
    t.integer "schema_version", default: 0
    t.boolean "enabled", default: true
  end

  create_table "layouts", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100
    t.text "content"
    t.string "content_type", limit: 40
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.integer "lock_version", default: 0
  end

  create_table "page_parts", id: :serial, force: :cascade do |t|
    t.text "name"
    t.string "filter_id", limit: 25
    t.text "content"
    t.integer "page_id"
    t.index ["page_id", "name"], name: "parts_by_page"
  end

  create_table "pages", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.string "slug", limit: 100
    t.string "breadcrumb", limit: 160
    t.integer "parent_id"
    t.integer "layout_id"
    t.string "class_name", limit: 25
    t.integer "status_id", default: 1, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "published_at", precision: nil
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.boolean "virtual", default: false, null: false
    t.integer "lock_version", default: 0
    t.string "description", limit: 255
    t.string "keywords", limit: 255
    t.index ["class_name"], name: "pages_class_name"
    t.index ["parent_id"], name: "pages_parent_id"
    t.index ["slug", "parent_id"], name: "pages_child_slug"
    t.index ["virtual", "status_id"], name: "pages_published"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "session_id", limit: 255
    t.text "data"
    t.datetime "updated_at", precision: nil
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "snippets", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100, default: "", null: false
    t.string "filter_id", limit: 25
    t.text "content"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.string "auto_export", limit: 512
    t.string "change_exec", limit: 512
    t.integer "lock_version", default: 0
    t.index ["name"], name: "name", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100
    t.string "email", limit: 255
    t.string "login", limit: 40, default: "", null: false
    t.string "password", limit: 40
    t.boolean "admin", default: false, null: false
    t.boolean "designer", default: false, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.text "notes"
    t.integer "lock_version", default: 0
    t.string "salt", limit: 255
    t.string "session_token", limit: 255
    t.string "locale", limit: 255
    t.index ["login"], name: "login", unique: true
  end
end
