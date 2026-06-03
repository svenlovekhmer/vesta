class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action -> { add_breadcrumb "Tableau de bord", dashboard_path }

  def index
    @missions = current_user.missions
                             .includes(:mission_status, :client, :decision_logs, steps: :step_status)
                             .order(created_at: :desc)

    @pending_logs_by_mission = @missions
      .select { |m| m.decision_logs.any? { |dl| dl.status == "pending" } }
      .map do |m|
        pending = m.decision_logs.select { |dl| dl.status == "pending" }
        {
          mission:      m,
          vesta_count:  pending.count { |dl| dl.owner_type == "provider" },
          client_count: pending.count { |dl| dl.owner_type == "client" },
          logs:         pending
        }
      end

    @total_vesta_pending  = @pending_logs_by_mission.sum { |h| h[:vesta_count] }
    @total_client_pending = @pending_logs_by_mission.sum { |h| h[:client_count] }

    @stats = {
      active:  @missions.count,
      clients: current_user.clients.count
    }
  end
end
