# frozen_string_literal: true
class JobsController < ApplicationController
  before_action :set_job, only: %i[show edit update destroy]
  before_action :authenticate_user!
  before_action :ensure_admin!
  with_themed_layout 'dashboard'

  # GET /jobs or /jobs.json
  def index
    add_breadcrumb I18n.t('hyrax.controls.home'), root_path
    add_breadcrumb I18n.t('hyrax.dashboard.title'), hyrax.dashboard_path if user_signed_in?
    add_breadcrumb I18n.t('tenejo.admin.sidebar.jobs'), jobs_path
    @jobs = Job.order(id: :desc)
  end

  # GET /jobs/1 or /jobs/1.json
  def show
    add_breadcrumb I18n.t('hyrax.controls.home'), hyrax.root_path
    add_breadcrumb I18n.t('hyrax.dashboard.title'), hyrax.dashboard_path if user_signed_in?
    add_breadcrumb I18n.t('tenejo.admin.sidebar.jobs'), jobs_path
  end

  # GET /jobs/new
  def new
    add_breadcrumb I18n.t('hyrax.controls.home'), hyrax.root_path
    add_breadcrumb I18n.t('hyrax.dashboard.title'), hyrax.dashboard_path if user_signed_in?
    add_breadcrumb I18n.t('tenejo.admin.sidebar.jobs'), jobs_path
    @job = Job.new
  end

  private

  def ensure_admin!
    authorize! :read, :admin_dashboard
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_job
    @job = Job.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def job_params
    params.require(:job).permit(:type, :label, :status, :completed_at, :collections, :works, :files)
  end
end
