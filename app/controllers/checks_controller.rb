# frozen_string_literal: true
class ChecksController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  with_themed_layout 'dashboard'
  def index
    @results = OkComputer::Registry.all.run
  end

  private

  def ensure_admin!
    authorize! :read, :admin_dashboard
  end
end
