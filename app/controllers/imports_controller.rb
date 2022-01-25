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
    import_graph = Tenejo::Preflight.process_csv(@job.manifest.download)
    @root = import_graph.root
  end

  def create
    @job = Import.new(job_params)
    @job.user = current_user

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
