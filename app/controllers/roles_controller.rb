# frozen_string_literal: true

# Controller for managing Roles
class RolesController < ApplicationController
  include Hydra::RoleManagement::RolesBehavior
  with_themed_layout 'dashboard'

  def destroy
    if @role.destroy
      redirect_to hyrax.admin_users_path(anchor: "roles"),
      notice: 'Role was successfully deleted.'
    else
      redirect_to hyrax.admin_users_path(anchor: "roles")
    end
  end
end
