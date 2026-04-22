class Prize < ApplicationRecord
  belongs_to :raffle
  has_many :winners, dependent: :destroy

  validates :title, :quantity, :draw_style, presence: true
  validates :draw_style, inclusion: { in: %w[burst reveal elimination] }

  # Ensure prizes are drawn in order of rank (e.g., lowest rank first)
  scope :ordered, -> { order(rank: :desc) }
end
