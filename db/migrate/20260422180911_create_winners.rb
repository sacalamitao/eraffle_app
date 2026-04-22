class CreateWinners < ActiveRecord::Migration[7.1]
  def change
    create_table :winners, id: :uuid do |t|
      t.references :prize, type: :uuid, null: false, foreign_key: true
      t.references :participant, type: :uuid, null: false, foreign_key: true

      # The specific 'ticket' that won
      t.references :entry, type: :uuid, null: false, foreign_key: true

      # For 'Reveal' style draws: False until the Facilitator clicks "Show Winner"
      t.boolean :is_revealed, default: false

      t.datetime :claimed_at
      t.timestamps
    end
  end
end
