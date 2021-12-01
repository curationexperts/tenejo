# frozen_string_literal: true
class ThemesController < ApplicationController
  before_action :set_theme, only: %i[show edit update destroy]
  before_action :authenticate_user!
  before_action :ensure_admin!
  with_themed_layout 'dashboard'

  # GET /themes or /themes.json
  # def index
  #   @themes = Theme.all
  # end
  #
  # # GET /themes/1 or /themes/1.json
  # def show
  # end
  #
  # # GET /themes/new
  # def new
  #   @theme = Theme.new
  # end

  # GET /themes/1/edit
  def edit
  end

  # POST /themes or /themes.json
  # def create
  #   @theme = Theme.new(theme_params)
  #
  #   respond_to do |format|
  #     if @theme.save
  #       format.html { redirect_to @theme, notice: "Theme was successfully created." }
  #       format.json { render :show, status: :created, location: @theme }
  #     else
  #       format.html { render :new, status: :unprocessable_entity }
  #       format.json { render json: @theme.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # PATCH/PUT /themes/1 or /themes/1.json
  def update
    params[:theme] = Theme::DEFAULTS if params[:reset]
    theme.logo.attach(params[:theme][:logo]) if params[:theme][:logo]
    if @theme.update(theme_params)
      redirect_to edit_theme_path
    else
      render edit_theme_path, status: :unprocessable_entity
    end
  end

  # DELETE /themes/1 or /themes/1.json
  # def destroy
  #   @theme.destroy
  #   respond_to do |format|
  #     format.html { redirect_to themes_url, notice: "Theme was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_theme
    # @theme = Theme.find(params[:id])
    @theme = Theme.current_theme
  end

  # Only allow a list of trusted parameters through.
  def theme_params
    params.require(:theme).permit(Theme::DEFAULTS.keys << :logo)
  end

  # Restrict theme access to admins
  def ensure_admin!
    authorize! :read, :admin_dashboard
  end
end
