# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :ensure_admin!, only: [:activate]
  def activate
    User.find(params[:id]).update(params.permit(:deactivated))
    flash[:notice] = params[:deactivated] == "true" ? "User deactivated" : "User reactivated"
    redirect_to hyrax.admin_users_path
  end

  def edit
    @user = User.find(params[:id])
  end

  private

  def ensure_admin!
    authorize! :read, :admin_dashboard
  end
end
