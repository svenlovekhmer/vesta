class DecisionLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_decision_log

  def update
    if @decision_log.update(decision_log_params)
      head :ok
    else
      render json: { errors: @decision_log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    mission = @decision_log.mission

    MissionStepBlocker.where(decision_log_id: @decision_log.id).destroy_all
    @decision_log.destroy!

    @remaining_pending = mission.decision_logs.where(status: "pending").to_a
    @decided_logs      = mission.decision_logs.where(status: "decided").order(decided_at: :desc).to_a
    @mission           = mission
    @entry             = build_entry(@remaining_pending)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def resolve_modal
    render layout: false
  end

  def resolve
    full_name = current_user.profile&.then { |p| "#{p.first_name} #{p.last_name}".strip }
    full_name = current_user.email if full_name.blank?

    @decision_log.update!(
      status:     "decided",
      decided_at: Date.current,
      decided_by: full_name
    )

    @affected_steps = MissionStepBlocker
      .where(decision_log_id: @decision_log.id, blocking_status: "blocking")
      .includes(step: [:step_status, :mission_step_blockers])
      .map(&:step)

    MissionStepBlocker
      .where(decision_log_id: @decision_log.id)
      .update_all(blocking_status: "resolved", resolved_at: Time.current)

    @affected_steps.each { |s| s.mission_step_blockers.reload }

    mission = @decision_log.mission
    @remaining_pending = mission.decision_logs.where(status: "pending").to_a
    @decided_logs      = mission.decision_logs.where(status: "decided").order(decided_at: :desc).to_a
    @mission           = mission
    @entry             = build_entry(@remaining_pending)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_decision_log
    mission_ids = current_user.missions.select(:id)
    @decision_log = DecisionLog.where(mission_id: mission_ids).find(params[:id])
  end

  def decision_log_params
    params.require(:decision_log).permit(:title, :description)
  end

  def build_entry(remaining)
    {
      vesta_count:  remaining.count { |dl| dl.owner_type == "provider" },
      client_count: remaining.count { |dl| dl.owner_type == "client" }
    }
  end
end
