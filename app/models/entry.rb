class Entry < ApplicationRecord
  belongs_to :raffle
  belongs_to :participant

  validates :source_type, presence: true

  validate :unique_sachet_code, if: -> { source_type == 'sachet_code' }

  private

  def unique_sachet_code
    # Logic to check metadata for duplicate codes
  end
end
