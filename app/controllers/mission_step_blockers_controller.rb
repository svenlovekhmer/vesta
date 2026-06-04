class MissionStepBlockersController < ApplicationController
  before_action :authenticate_user!

  def create
    mission = current_user.missions.find(params[:mission_id])
    step = mission.steps.find(params[:step_id])
    decision_log = mission.decision_logs.where(status: "pending").find(params[:decision_log_id])

    head :unprocessable_entity and return if step.step_status.title == "Validée"

    @blocker = MissionStepBlocker.find_or_create_by!(
      decision_log: decision_log,
      step: step,
      blocking_status: "blocking"
    ) { |b| b.mission = mission }

    @blocker.step.mission_step_blockers.reload
    @blocker.decision_log.mission_step_blockers.reload

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    blocker = MissionStepBlocker
      .joins(:mission)
      .where(missions: { id: current_user.missions.select(:id) })
      .find(params[:id])

    @step = blocker.step
    @decision_log = blocker.decision_log
    blocker.destroy

    @step.mission_step_blockers.reload
    @decision_log.mission_step_blockers.reload

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def blocker_params
    params.permit(:decision_log_id, :step_id, :mission_id)
  end
end
