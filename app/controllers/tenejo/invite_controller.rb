# frozen_string_literal: true
class Tenejo::InviteController < Devise::InvitationsController
  before_action :configure_permitted_parameters
  layout :resolve_layout

  protected

  # form was modified to include new role_ids param, so we have to tell devise about it
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:invite) do |pr|
      pr.permit(:email, role_ids: [])
    end
  end

  private

  def resolve_layout
    action_name == 'edit' ? 'hyrax' : 'hyrax/dashboard'
  end
end
