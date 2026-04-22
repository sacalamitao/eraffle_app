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

ActiveRecord::Schema[7.1].define(version: 2026_04_22_175519) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_graphql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "supabase_vault"
  enable_extension "uuid-ossp"

  create_table "entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "raffle_id", null: false
    t.uuid "participant_id", null: false
    t.string "source_type", default: "check_in", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_entries_on_participant_id"
    t.index ["raffle_id"], name: "index_entries_on_raffle_id"
  end

  create_table "participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "raffle_id", null: false
    t.uuid "profile_id"
    t.string "display_name", null: false
    t.boolean "checked_in", default: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_participants_on_profile_id"
    t.index ["raffle_id", "profile_id"], name: "index_participants_on_raffle_id_and_profile_id", unique: true, where: "(profile_id IS NOT NULL)"
    t.index ["raffle_id"], name: "index_participants_on_raffle_id"
  end

  create_table "prizes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "raffle_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "quantity", default: 1
    t.integer "rank", default: 1
    t.string "draw_style", default: "reveal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raffle_id"], name: "index_prizes_on_raffle_id"
  end

  create_table "profiles", id: :uuid, default: nil, force: :cascade do |t|
    t.text "email"
    t.integer "tickets_count", default: 0
    t.text "external_identifier"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.index ["email"], name: "index_profiles_on_email", unique: true
  end

  create_table "raffles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "facilitator_id", null: false
    t.string "title", null: false
    t.string "slug", null: false
    t.string "category", default: "private"
    t.string "status", default: "draft"
    t.string "access_code"
    t.boolean "must_be_present", default: false
    t.integer "max_entries_per_user", default: 1
    t.jsonb "branding_settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_code"], name: "index_raffles_on_access_code", unique: true
    t.index ["facilitator_id"], name: "index_raffles_on_facilitator_id"
    t.index ["slug"], name: "index_raffles_on_slug", unique: true
  end

  add_foreign_key "entries", "participants"
  add_foreign_key "entries", "raffles"
  add_foreign_key "participants", "profiles"
  add_foreign_key "participants", "raffles"
  add_foreign_key "prizes", "raffles"
  add_foreign_key "profiles", "auth.users", column: "id", name: "fk_profiles_users", on_delete: :cascade
  add_foreign_key "raffles", "profiles", column: "facilitator_id"
end
