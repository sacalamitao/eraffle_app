# frozen_string_literal: true
# app/controllers/application_controller.rb
require 'net/http'

class ApplicationController < ActionController::API
  before_action :authenticate_profile!

  def current_profile
    @current_profile ||= begin
      # 1. Extract token from Authorization: Bearer <token> header
      token = request.headers['Authorization']&.split(' ')&.last
      return nil unless token

      # 2. Define the JWKS URL (your Project ID is key here)
      project_id = ENV['SUPABASE_PROJECT_ID']
      jwks_url = "https://#{project_id}.supabase.co/auth/v1/.well-known/jwks.json"

      # 3. Fetch and cache keys (caching is essential for speed!)
      jwks_loader = ->(options) do
        @cached_keys ||= JWT::JWK::Set.new(JSON.parse(Net::HTTP.get(URI(jwks_url))))
        @cached_keys.export
      end

      # 4. Decode the token (Supabase uses ES256 for ECC keys)
      payload = JWT.decode(token, nil, true, { 
        algorithm: 'ES256', 
        jwks: jwks_loader,
        verify_aud: true,
        aud: 'authenticated' # Supabase default audience
      })

      # 5. Link to your Profile model
      Profile.find_by(id: payload[0]['sub'])
    rescue JWT::DecodeError => e
      Rails.logger.error "Auth Error: #{e.message}"
      nil
    end
  end

  def authenticate_profile!
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_profile
  end
end
