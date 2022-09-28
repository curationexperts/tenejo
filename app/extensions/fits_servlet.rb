# frozen_string_literal: true
require 'hydra/file_characterization/characterizer'
require 'hydra/file_characterization/characterizers/fits_servlet'
Hydra::FileCharacterization::Characterizers::FitsServlet.class_eval do
  protected

  def command
    format(%[curl -s -k -F datafile=@- #{ENV['FITS_SERVLET_URL']}/examine < %s], Shellwords.escape(filename))
  end
end
