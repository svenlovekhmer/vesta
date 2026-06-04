class StepsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_step

  def update
    if @step.update(step_params)
      advance_next_step if @step.step_status.title == "Validée"
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to mission_path(@step.mission) }
        format.json { head :ok }
      end
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
    params.require(:step).permit(:title, :description, :step_status_id)
  end

  def advance_next_step
    a_faire = StepStatus.find_by(title: "À faire")
    en_cours = StepStatus.find_by(title: "En cours")
    next_step = Step.where(mission: @step.mission)
                    .where("position > ?", @step.position)
                    .order(:position)
                    .first
    if next_step&.step_status == a_faire
      next_step.update(step_status: en_cours)
      @next_step = next_step
    end
  end
end
