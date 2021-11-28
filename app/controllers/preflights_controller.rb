# frozen_string_literal: true
class PreflightsController < JobsController
  with_themed_layout 'dashboard'

  def index
    redirect_to jobs_url
  end

  def new
    @job = Preflight.new
  end

  def create
    @job = Preflight.new(job_params.merge({ user: current_user }))

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
end
