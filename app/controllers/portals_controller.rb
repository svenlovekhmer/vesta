class PortalsController < ApplicationController
  layout "portal"

  def show
    @mission = Mission
      .includes(:mission_status, client: :user, steps: :step_status,
                decision_logs: { mission_step_blockers: :step })
      .find_by!(portal_token: params[:token])

    @architect    = @mission.client.user
    @profile      = @architect.profile
    @pending_logs = @mission.decision_logs.select { |l| l.status == "pending" }.sort_by(&:created_at).reverse
    @decided_logs = @mission.decision_logs.select { |l| l.status == "decided" }.sort_by { |l| l.decided_at || l.created_at }.reverse
    @steps_total  = @mission.steps.size
    @steps_done   = @mission.steps.count { |s| s.step_status.title == "Validée" }
    @progress     = @steps_total > 0 ? (@steps_done.to_f / @steps_total * 100).round : 0
  rescue ActiveRecord::RecordNotFound
    render file: "public/404.html", status: :not_found
  end
end
