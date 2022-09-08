# frozen_string_literal: true
# This patches minimagic to force utf encoding on shell output
require 'mini_magick/shell'

MiniMagick::Shell.class_eval do
  def run(command, options = {})
    stdout, stderr, status = execute(command, stdin: options[:stdin])

    stdout = stdout.force_encoding(Encoding::UTF_8)
    stderr = stderr.force_encoding(Encoding::UTF_8) # otherwise comes back 8bit-ascii

    raise MiniMagick::Error, "`#{command.join(' ')}` failed with error:\n#{stderr}" if status != 0 && options.fetch(:whiny, MiniMagick.whiny)

    $stderr.print(stderr) unless options[:stderr] == false

    [stdout, stderr, status]
  end
end
