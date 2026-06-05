class DecisionLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_decision_log, only: [:update, :destroy, :resolve_modal, :resolve]

  def new_modal
    @mission = current_user.missions.find(params[:mission_id])
    @decision_log = DecisionLog.new
    render layout: false
  end

  def create
    @mission     = current_user.missions.find(params.dig(:decision_log, :mission_id))
    step_id      = blocker_create_params[:step_id].presence
    document_id  = blocker_create_params[:document_id].presence
    @blocker_mode = step_id.present?

    @decision_log = @mission.decision_logs.build(create_params)

    ActiveRecord::Base.transaction do
      @decision_log.save!
      if step_id
        step = @mission.steps.find(step_id)
        MissionStepBlocker.create!(
          mission:             @mission,
          step:                step,
          decision_log:        @decision_log,
          blocking_status:     "blocking",
          step_title:          step.title,
          decision_log_title:  @decision_log.title
        )
      end
      if document_id
        doc = @mission.documents.find(document_id)
        DecisionLogDocument.create!(decision_log: @decision_log, document: doc)
      end
    end

    @pending_logs = @mission.decision_logs.where(status: "pending").to_a
    @entry        = build_entry(@pending_logs)

    respond_to do |f|
      f.turbo_stream { render @blocker_mode ? "create_blocker" : "create" }
    end
  rescue ActiveRecord::RecordInvalid => e
    @decision_log.errors.add(:base, e.message) unless @decision_log.errors.any?
    @blocker_mode = step_id.present?
    respond_to do |f|
      f.turbo_stream { render @blocker_mode ? "create_blocker" : "create" }
    end
  end

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

  def create_params
    params.require(:decision_log).permit(:title, :description, :owner_type)
  end

  def blocker_create_params
    params.require(:decision_log).permit(:step_id, :document_id)
  end

  def build_entry(remaining)
    {
      vesta_count:  remaining.count { |dl| dl.owner_type == "provider" },
      client_count: remaining.count { |dl| dl.owner_type == "client" }
    }
  end
end
