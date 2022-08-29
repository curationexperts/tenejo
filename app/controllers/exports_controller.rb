# frozen_string_literal: true

class ExportsController < JobsController
  with_themed_layout 'dashboard'

  def index
    redirect_to jobs_path
  end

  def new
    @job = Export.new
  end

  def show
    super
    add_breadcrumb "##{@job.id} - #{I18n.t('tenejo.admin.sidebar.exports')}", @job
  end

  def create
    @job = Export.new(job_params.merge({ user: current_user, status: :submitted }))
    respond_to do |format|
      if @job.save
        BatchExportJob.perform_later(@job)
        format.html { redirect_to @job }
        format.json { render :show, status: :created, location: @job }
      end
    end
  end

  private

  def job_params
    params.require(:export).permit(identifiers: [])
  end
end
