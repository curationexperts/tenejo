# frozen_string_literal: true
module Tenejo
  ##
  # This implementation simply calls out to clamdscan (or whatever else you pass in to the executable arg)
  ##
  class VirusScanner < Hydra::Works::VirusScanner
    def initialize(file, executable = "clamdscan")
      super file
      @executable = executable
    end

    def infected?
      system(format("%s --no-summary --quiet '%s'", @executable, file))
      case $CHILD_STATUS.exitstatus
      when 0 # no vir
        false
      when 1 # vir found
        true
      when 2 # something else
        raise "File not found `#{file}`"
      else
        raise "Unknown exit code #{$CHILD_STATUS.exitstatus}" # Very something else
      end
    end
  end
end
