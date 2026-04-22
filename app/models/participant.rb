class Participant < ApplicationRecord
  belongs_to :raffle
  # optional: true allows Private Raffle guests to join without a profile
  belongs_to :profile, optional: true

  has_many :entries, dependent: :destroy

  validates :display_name, presence: true

  def entry_count
    entries.count
  end
end
