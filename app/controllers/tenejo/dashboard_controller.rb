# frozen_string_literal: true
module Tenejo
  class DashboardController < Hyrax::DashboardController
    Hyrax::DashboardController.sidebar_partials[:jobs] = []
  end
end
