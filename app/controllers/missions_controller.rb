class MissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission, only: [:show]

  def index
    @missions = current_user.missions
  end

  def new
    @mission = Mission.new
    @clients = current_user.clients
    @step_templates = current_user.step_templates.includes(:step_template_items)
    @step_templates_json = build_templates_json(@step_templates)
  end

  def create
    @mission = Mission.new(mission_params)
    @mission.mission_status = MissionStatus.find_by(title: "En attente")
    if @mission.save
      redirect_to mission_path(@mission), notice: "La mission a été créée avec succès."
    else
      @clients = current_user.clients
      @step_templates = current_user.step_templates.includes(:step_template_items)
      @step_templates_json = build_templates_json(@step_templates)
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_mission
    @mission = current_user.missions.find(params[:id])
  end

  def build_templates_json(templates)
    templates.map do |t|
      { id: t.id, name: t.name,
        items: t.step_template_items.map { |i| { title: i.title } } }
    end.to_json
  end

  def mission_params
    params.require(:mission).permit(
      :title, :description, :client_id,
      steps_attributes: [:id, :title, :position, :_destroy]
    )
  end
end
