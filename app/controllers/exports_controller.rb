class ExportsController < JobsController
  with_themed_layout 'dashboard'

  def index
    redirect_to jobs_path
  end

  def new
    redirect_to new_export_path
  end

  def show
  end

  
end
