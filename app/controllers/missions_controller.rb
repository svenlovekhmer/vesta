class MissionsController < ApplicationController
  def new
    @mission = Mission.new
  end

  def create
    @mission = Mission.new(mission_params)
    # if @mission.save
    #   redirect_to root_path, notice: "Mission created successfully."
    # else
    #   render :new
    # end
  end

  private

  def mission_params
    params.require(:mission).permit(:title, :client_id, :step_template_id)
  end
end
