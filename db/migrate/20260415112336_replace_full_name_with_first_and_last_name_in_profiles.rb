class ReplaceFullNameWithFirstAndLastNameInProfiles < ActiveRecord::Migration[7.1]
  def up
    add_column :profiles, :first_name, :string
    add_column :profiles, :last_name, :string

    execute <<-SQL
      UPDATE profiles
      SET first_name = split_part(full_name, ' ', 1),
          last_name = split_part(full_name, ' ', 2)
    SQL

    remove_column :profiles, :full_name
  end

  def down
    add_column :profiles, :full_name, :text

    execute <<-SQL
      UPDATE profiles
      SET full_name = first_name || ' ' || last_name
    SQL

    remove_column :profiles, :first_name
    remove_column :profiles, :last_name
  end
end
