# frozen_string_literal: true
require 'clamby/error'
module Tenejo
  ##
  # A Clamby based virus scanner
  #
  # @see https://github.com/kobaltz/clamby/blob/master/README.md
  class VirusScanner < Hydra::Works::VirusScanner
    Clamby.config[:daemonize] = true if Rails.env.production?
    def infected?
      Clamby.virus?(file)
    end
  end
end
