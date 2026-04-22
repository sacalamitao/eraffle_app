# frozen_string_literal: true

class Profile < ApplicationRecord
  # Since we used a custom ID from Supabase Auth
  self.primary_key = 'id'
  # Raffles this user is hosting
  has_many :hosted_raffles, class_name: 'Raffle', foreign_key: 'facilitator_id', dependent: :destroy

  # Raffles this user has joined as a player
  has_many :participants, dependent: :destroy
  has_many :joined_raffles, through: :participants, source: :raffle
end
