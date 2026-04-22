class CreateParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :participants, id: :uuid do |t|
      t.references :raffle, type: :uuid, null: false, foreign_key: true
      t.references :profile, type: :uuid, null: true, foreign_key: true

      t.string :display_name, null: false
      t.boolean :checked_in, default: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :participants, %i[raffle_id profile_id], unique: true, where: 'profile_id IS NOT NULL'
  end
end
