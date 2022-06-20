# frozen_string_literal: true
module Clamby
  class Command
    class << self
      def scan(path)
        return nil unless file_exists?(path)
        args = build_args(path)
        new.run scan_executable, *args
        handle_status($CHILD_STATUS&.exitstatus)
      end

      private

      def handle_status(status)
        # $CHILD_STATUS maybe nil if the execution itself (not the client process)
        case status
        when 0
          false
        when nil, 2
          # clamdscan returns 2 whenever error other than a detection happens
          maybe_raise_client_error
        else
          maybe_raise_virus_detected
        end
        true
      end

      def maybe_raise_virus_detected
        raise Clamby::VirusDetected, "VIRUS DETECTED on #{Time.zone.now}: #{path}" if Clamby.config[:error_file_virus]
      end

      def maybe_raise_client_error
        raise Clamby::ClamscanClientError, "Clamscan client error" if Clamby_config[:daemonize] && Clamby.config[:error_clamscan_client_error]
      end

      def config_fdpass(args)
        args << '--fdpass' if Clamby.config[:daemonize] && Clamby.config[:fdpass]
      end

      def config_stream(args)
        args << '--stream' if Clamby.config[:daemonize] && Clamby.config[:fdpass]
      end

      def config_datadir(args)
        args << "-d #{Clamby.config[:datadir]}" if Clamby.config[:datadir]
      end

      def build_args(path)
        # path has to be quoted, since we're sending this arg directly to the shell w/ system()
        args = ["'#{path}'", '--no-summary']
        config_fdpass(args)
        config_stream(args)
        config_datadir(args)
      end
    end
  end
end
