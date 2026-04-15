class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles, id: false do |t|
      t.uuid :id, primary_key: true
      t.text :full_name
      t.text :email
      t.text :role, default: "participant"
      t.integer :tickets_count, default: 0
      t.text :external_identifier
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :profiles, :email, unique: true

    # Add constraint for role
    execute <<~SQL
      ALTER TABLE profiles
      ADD CONSTRAINT role_check
      CHECK (role IN ('admin', 'facilitator', 'participant'));
    SQL

    # Add foreign key to Supabase auth.users
    execute <<~SQL
      ALTER TABLE profiles
      ADD CONSTRAINT fk_profiles_users
      FOREIGN KEY (id)
      REFERENCES auth.users(id)
      ON DELETE CASCADE;
    SQL
  end
end
