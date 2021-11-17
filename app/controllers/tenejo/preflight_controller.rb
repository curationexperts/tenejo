# frozen_string_literal: true
class Tenejo::PreflightController < ApplicationController
  def new
  end

  def show
    @original_file = session[:source_file]
    @manifest = session[:manifest]
    @preflight_graph = Tenejo::Preflight.read_csv(@manifest, 'tmp/uploads')
    File.delete(@manifest)
    @errors = @preflight_graph[:fatal_errors]
    @warnings = @preflight_graph[:warnings]
    @collections = @preflight_graph[:collection]
    @works = @preflight_graph[:work]
    @files = @preflight_graph[:file]
  end

  def upload
    uploaded_io = params[:manifest]
    manifest = Tempfile.open(['manifest', '.csv'], Rails.root.join('tmp', 'uploads'))
    manifest.write(uploaded_io.read)
    manifest.close
    session[:source_file] = uploaded_io.original_filename
    session[:manifest] = manifest.path
    redirect_to tenejo_preflight_show_path
  end
end
