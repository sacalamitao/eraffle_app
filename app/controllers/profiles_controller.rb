# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  def show_me
    render json: current_profile
  end
end
