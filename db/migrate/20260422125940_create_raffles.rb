class CreateRaffles < ActiveRecord::Migration[7.1]
  def change
    create_table :raffles, id: :uuid do |t|
      # Link to your existing profiles table
      t.references :facilitator, type: :uuid, null: false, foreign_key: { to_table: :profiles }

      t.string :title, null: false
      t.string :slug, null: false
      t.string :category, default: 'private' # private, influencer, brand
      t.string :status, default: 'draft'     # draft, active, completed
      t.string :access_code

      # Rules
      t.boolean :must_be_present, default: false
      t.integer :max_entries_per_user, default: 1

      # Future-proofing UI
      t.jsonb :branding_settings, default: {}

      t.timestamps
    end

    add_index :raffles, :slug, unique: true
    add_index :raffles, :access_code, unique: true
  end
end
