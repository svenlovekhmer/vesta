class MissionsController < ApplicationController
  def index
    @missions = Mission.all
  end

  def new
    @mission = Mission.new
  end

  def create
    @mission = Mission.new(mission_params)
    @mission.mission_status = MissionStatus.find_by(title: "En attente")
    if @mission.save
      redirect_to mission_path(@mission), notice: "La mission a été créée avec succès."
    else
      render :new
    end
  end

  def show
  end

  private

  def mission_params
    params.require(:mission).permit(:title, :description, :client_id)
  end
end
