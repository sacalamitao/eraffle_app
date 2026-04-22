class CreatePrizes < ActiveRecord::Migration[7.1]
  def change
    create_table :prizes, id: :uuid do |t|
      t.references :raffle, type: :uuid, null: false, foreign_key: true

      t.string :title, null: false
      t.text :description
      t.integer :quantity, default: 1
      t.integer :rank, default: 1 # 1 for Grand Prize, 10 for minor prizes

      # styles: 'burst', 'reveal', 'elimination'
      t.string :draw_style, default: 'reveal'

      t.timestamps
    end
  end
end
