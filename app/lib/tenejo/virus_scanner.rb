# frozen_string_literal: true
module Tenejo
  ##
  # This implementation simply calls out to clamdscan (or whatever else you pass in to the executable arg)
  ##
  class VirusScanner < Hydra::Works::VirusScanner
    def initialize(file, executable = ENV.fetch('CLAMSCAN_EXEC', 'clamscan'))
      super file
      @executable = executable
    end

    def infected?
      system(format("%s --no-summary --quiet #{@executable == 'clamdscan' ? '--fdpass' : ''} %s >/dev/null 2>&1", @executable, Shellwords.escape(file)))
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
