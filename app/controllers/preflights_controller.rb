# frozen_string_literal: true
class PreflightsController < JobsController
  with_themed_layout 'dashboard'

  def index
    redirect_to jobs_url
  end

  def new
    super
    @job = Preflight.new
    add_breadcrumb @job.class.name, @job
  end

  def show
    super
    @preflight_graph = Tenejo::Preflight.process_csv(@job.manifest.download)
    @root = JSON.parse(@preflight_graph.root.to_json)
    add_breadcrumb "##{@job.id} - #{@job.class.name}", @job
  end

  def create
    @job = Preflight.new(job_params.merge({ user: current_user }))
    @job.graph = run_preflight(@job) if @job.validate

    respond_to do |format|
      if @job.save
        format.html { redirect_to @job }
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
    job.collections = preflight_graph.collections.count
    job.works = preflight_graph.works.count
    job.files = preflight_graph.files.count
    job.completed_at = Time.current
    job.status = :completed
    preflight_graph
  end
end
