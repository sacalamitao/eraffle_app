class Winner < ApplicationRecord
  belongs_to :prize
  belongs_to :participant
  belongs_to :entry

  # Use a scope for the Real-time Big Screen
  scope :revealed, -> { where(is_revealed: true) }
end
