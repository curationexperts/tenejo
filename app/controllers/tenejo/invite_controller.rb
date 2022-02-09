# frozen_string_literal: true
class Tenejo::InviteController < Devise::InvitationsController
  before_action :configure_permitted_parameters
  with_themed_layout 'dashboard'
  
  protected

  # form was modified to include new role_ids param, so we have to tell devise about it
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite) do |pr|
      pr.permit(:email, role_ids: [])
    end
  end
end
