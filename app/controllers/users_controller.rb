# frozen_string_literal: true
class UsersController < ApplicationController
  before_action :ensure_admin!, only: [:activate, :edit, :update]
  before_action :load_user, only: [:edit, :update]
  with_themed_layout 'dashboard'
  def activate
    User.find(params[:id]).update(params.permit(:deactivated))
    flash[:notice] = params[:deactivated] == "true" ? "User deactivated" : "User reactivated"
    redirect_to hyrax.admin_users_path
  end

  def edit
  end

  def update
    @user.display_name = params[:user][:display_name]
    @user.save!
    flash[:notice] = "User updated"
    redirect_to hyrax.admin_users_path
  end

  private

  def load_user
    @user = User.find(params[:id])
  end

  def ensure_admin!
    authorize! :read, :admin_dashboard
  end
end
