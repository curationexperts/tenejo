# frozen_string_literal: true

class ExportsController < JobsController
  with_themed_layout 'dashboard'

  def index
    redirect_to jobs_path
  end

  def new
    super
    redirect_to new_export_path
  end

  def show
    super
    add_breadcrumb "##{@job.id} - #{I18n.t('tenejo.admin.sidebar.exports')}", @job
  end
end
