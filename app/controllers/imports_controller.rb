# frozen_string_literal: true
class ImportsController < JobsController
  with_themed_layout 'dashboard'

  def index
    redirect_to jobs_path
  end

  def new
    redirect_to new_preflight_path
  end

  def show
    job = Job.find(params[:id])
    g = Tenejo::Graph.new
    g.attributes = job.graph
    @root = g.root
  end

  def create
    @job = Import.new(job_params)
    @job.user = current_user
    @job.graph = Tenejo::Preflight.process_csv(@job.manifest.download)

    respond_to do |format|
      if @job.save
        BatchImportJob.perform_later(@job)
        format.html { redirect_to @job, notice: "Job was successfully created." }
        format.json { render :show, status: :created, location: @job }
      end
    end
  end

  private

  # Only allow a list of trusted parameters through.
  def job_params
    params.require(:import).permit(:parent_job_id)
  end
end
