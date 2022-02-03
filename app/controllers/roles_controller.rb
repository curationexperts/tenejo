# frozen_string_literal: true

# Controller for managing Roles
class RolesController < ApplicationController
  include Hydra::RoleManagement::RolesBehavior
  with_themed_layout 'dashboard'
end