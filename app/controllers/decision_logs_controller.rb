class DecisionLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_decision_log

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

    if defined?(MissionStepBlocker)
      MissionStepBlocker
        .where(decision_log_id: @decision_log.id)
        .update_all(blocking_status: "resolved", resolved_at: Time.current)
    end

    mission = @decision_log.mission
    @remaining_pending = mission.decision_logs.where(status: "pending").to_a
    @mission            = mission
    @entry              = build_entry(@remaining_pending)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_decision_log
    mission_ids = current_user.missions.select(:id)
    @decision_log = DecisionLog.where(mission_id: mission_ids).find(params[:id])
  end

  def build_entry(remaining)
    {
      vesta_count:  remaining.count { |dl| dl.owner_type == "provider" },
      client_count: remaining.count { |dl| dl.owner_type == "client" }
    }
  end
end
