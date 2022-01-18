# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action do
    @announcement_text = ContentBlock.for(:announcement)
  end
  rescue_from Net::SMTPFatalError, with: :mail_error
  helper Hyrax::Engine.helpers
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  skip_after_action :discard_flash_if_xhr
  include Hydra::Controller::ControllerBehavior

  # Adds Hyrax behaviors into the application controller
  include Hyrax::Controller
  include Hyrax::ThemedLayoutController
  include HttpAuthConcern
  with_themed_layout '1_column'

  private

  def mail_error(e)
    flash[:error] = "There seems to be a problem with the mail system. Invitation was not sent."
    logger.error("Mailer error: #{e.message}")
    logger.error(e.backtrace.join("\n"))
    redirect_to dashboard_path
  end
end
