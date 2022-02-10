# frozen_string_literal: true
class Tenejo::RegistrationsController < ApplicationController
  def edit
    @user = User.where(email: params[:id]).first
  end

  def update
    @user = User.where(email: params[:id]).first
    @user.display_name = params[:user][:display_name]
    @user.save!
    flash[:notice] = "User updated"
    redirect_to hyrax.admin_users_path
  end
end
