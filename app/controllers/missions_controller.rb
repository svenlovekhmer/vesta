class MissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission, only: [:show]

  def index
    @missions = current_user.missions
  end

  def new
    @mission = Mission.new
    @clients = current_user.clients
  end

  def create
    @mission = Mission.new(mission_params)
    @mission.mission_status = MissionStatus.find_by(title: "En attente")
    if @mission.save
      redirect_to mission_path(@mission), notice: "La mission a été créée avec succès."
    else
      @clients = current_user.clients
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_mission
    @mission = current_user.missions.find(params[:id])
  end

  def mission_params
    params.require(:mission).permit(:title, :description, :client_id)
  end
end
