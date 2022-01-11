# frozen_string_literal: true

module FooterHelper
  # returns true if running in a full production environment
  def production_host?
    return false if request.host == 'localhost' # dev and test environments
    return false if request.host.include?('-')  # hostnames like qa-etd, tenejo-dev
    true # hostnames without a dash
  end
end
