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
    ) do |b|
      b.mission = mission
      b.step_title = step.title
      b.decision_log_title = decision_log.title
    end

    @blocker.step&.mission_step_blockers&.reload
    @blocker.decision_log&.mission_step_blockers&.reload

    respond_to do |format|
      format.turbo_stream
    end
  rescue => e
    Rails.logger.error "[MissionStepBlocker#create] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    head :unprocessable_entity
  end

  def destroy
    blocker = MissionStepBlocker
      .joins(:mission)
      .where(missions: { id: current_user.missions.select(:id) }, blocking_status: "blocking")
      .find(params[:id])

    @step         = blocker.step
    @decision_log = blocker.decision_log
    blocker.destroy

    @step.mission_step_blockers.reload
    @decision_log.mission_step_blockers.reload

    if params[:document_id].present?
      @document = Document.joins(:mission)
                          .where(missions: { id: current_user.missions.select(:id) })
                          .includes(:step)
                          .find_by(id: params[:document_id])
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def blocker_params
    params.permit(:decision_log_id, :step_id, :mission_id)
  end
end
