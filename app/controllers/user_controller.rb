# frozen_string_literal: true
class UserController < ApplicationController
  def update
    User.find(params[:id]).update(params.permit(:deactivated))
    flash[:notice] = params[:deactivated] == "true" ? "User deactivated" : "User reactivated"
    redirect_to hyrax.admin_users_path
  end
end
