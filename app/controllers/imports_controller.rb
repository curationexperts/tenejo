# frozen_string_literal: true
class ImportsController < JobsController
  with_themed_layout 'dashboard'

  def index
    redirect_to jobs_path
  end

  def new
    super
    redirect_to new_preflight_path
  end

  def show
    super
    @job = Job.find(params[:id])
    add_breadcrumb "##{@job.id} - #{I18n.t('tenejo.admin.sidebar.imports')}", @job
  end

  def create
    @job = Import.new(job_params)
    update_submission_status(@job)

    respond_to do |format|
      if @job.save
        BatchImportJob.perform_later(@job)
        format.html { redirect_to @job }
        format.json { render :show, status: :created, location: @job }
      end # maybe throw an exception if we can't save?
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def job_params
    params.require(:import).permit(:parent_job_id)
  end

  def update_submission_status(job)
    job.user = current_user
    job.status = :submitted
    job.graph = Tenejo::Preflight.process_csv(job.manifest.download)
    job.collections = job.graph.collections.count
    job.works = job.graph.works.count
    job.files = job.graph.files.count
  end
end
