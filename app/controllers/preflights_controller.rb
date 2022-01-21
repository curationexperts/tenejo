# frozen_string_literal: true
class PreflightsController < JobsController
  with_themed_layout 'dashboard'

  def index
    redirect_to jobs_url
  end

  def new
    @job = Preflight.new
  end

  def show
    @preflight_graph = Tenejo::Preflight.process_csv(@job.manifest.download)
  end

  def create
    @job = Preflight.new(job_params.merge({ user: current_user }))
    @graph = run_preflight(@job) if @job.validate

    respond_to do |format|
      if @job.save
        format.html { redirect_to @job, notice: "Job was successfully created." }
        format.json { render :show, status: :created, location: @job }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # Only allow a list of trusted parameters through.
  def job_params
    params.require(:preflight).permit(:manifest)
  end

  private

  def run_preflight(job)
    manifest = job_params[:manifest].tempfile.path
    preflight_graph = Tenejo::Preflight.read_csv(manifest)
    job.collections = preflight_graph[:collection].count
    job.works = preflight_graph[:work].count
    job.files = preflight_graph[:file].count
    job.completed_at = Time.current
    job.status = :completed
    preflight_graph
  end
end
