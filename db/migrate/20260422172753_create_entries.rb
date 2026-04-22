class CreateEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :entries, id: :uuid do |t|
      t.references :raffle, type: :uuid, null: false, foreign_key: true
      t.references :participant, type: :uuid, null: false, foreign_key: true

      # Examples: 'check_in', 'sachet_code', 'social_share'
      t.string :source_type, default: 'check_in', null: false

      # To store which specific Sachet QR code was used, or social media post link
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end
