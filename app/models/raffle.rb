class Raffle < ApplicationRecord
  belongs_to :facilitator, class_name: 'Profile', foreign_key: 'facilitator_id'
  has_many :participants, dependent: :destroy
  has_many :entries, dependent: :destroy
  has_many :profiles, through: :participants
  has_many :prizes, dependent: :destroy

  validates :title, presence: true
  validates :category, inclusion: { in: %w[private influencer brand] }

  # Generate a unique slug and access code before saving
  before_validation :generate_identifiers, on: :create

  private

  def generate_identifiers
    self.slug ||= title.parameterize + "-#{SecureRandom.hex(3)}"
    self.access_code ||= SecureRandom.alphanumeric(6).upcase
  end
end
