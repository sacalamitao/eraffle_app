# frozen_string_literal: true
class Profile < ApplicationRecord
  # Since we used a custom ID from Supabase Auth
  self.primary_key = 'id'

  # Optional: Tell Rails about the relationship
  # belongs_to :user (We'll set this up once you have Auth logic)
end
