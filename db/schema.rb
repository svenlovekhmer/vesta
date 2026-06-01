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

ActiveRecord::Schema[8.1].define(version: 2026_06_01_135918) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "clients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "decision_logs", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.date "decided_at"
    t.string "decided_by"
    t.bigint "mission_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["mission_id"], name: "index_decision_logs_on_mission_id"
  end

  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_type"
    t.string "file_url"
    t.string "name"
    t.bigint "step_id", null: false
    t.datetime "updated_at", null: false
    t.index ["step_id"], name: "index_documents_on_step_id"
  end

  create_table "mission_statuses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "missions", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.bigint "mission_status_id", null: false
    t.string "portal_token"
    t.bigint "step_template_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_missions_on_client_id"
    t.index ["mission_status_id"], name: "index_missions_on_mission_status_id"
    t.index ["step_template_id"], name: "index_missions_on_step_template_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "logo_url"
    t.string "profession"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "step_statuses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "step_template_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "position"
    t.bigint "step_template_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["step_template_id"], name: "index_step_template_items_on_step_template_id"
  end

  create_table "step_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "is_default"
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_step_templates_on_user_id"
  end

  create_table "steps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "mission_id", null: false
    t.integer "position"
    t.bigint "step_status_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.datetime "validate_at", precision: nil
    t.index ["mission_id"], name: "index_steps_on_mission_id"
    t.index ["step_status_id"], name: "index_steps_on_step_status_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "clients", "users"
  add_foreign_key "decision_logs", "missions"
  add_foreign_key "documents", "steps"
  add_foreign_key "missions", "clients"
  add_foreign_key "missions", "mission_statuses"
  add_foreign_key "missions", "step_templates"
  add_foreign_key "profiles", "users"
  add_foreign_key "step_template_items", "step_templates"
  add_foreign_key "step_templates", "users"
  add_foreign_key "steps", "missions"
  add_foreign_key "steps", "step_statuses"
end
