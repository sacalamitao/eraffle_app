class RemoveRoleFromProfiles < ActiveRecord::Migration[7.1]
  def up
    execute 'ALTER TABLE profiles DROP CONSTRAINT IF EXISTS role_check;'

    remove_column :profiles, :role, :text
  end

  def down
    add_column :profiles, :role, :text, default: 'participant'
    execute "ALTER TABLE profiles ADD CONSTRAINT role_check CHECK (role = ANY (ARRAY['admin'::text, 'facilitator'::text, 'participant'::text]));"
  end
end
