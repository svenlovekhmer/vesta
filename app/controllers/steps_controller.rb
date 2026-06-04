class StepsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_step

  def update
    if @step.update(step_params)
      head :ok
    else
      render json: { errors: @step.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_step
    mission_ids = current_user.missions.select(:id)
    @step = Step.where(mission_id: mission_ids).find(params[:id])
  end

  def step_params
    params.require(:step).permit(:title, :description)
  end
end
