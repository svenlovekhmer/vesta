class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action -> { add_breadcrumb "Tableau de bord", root_path }

  def index
    @missions = current_user.missions
                             .includes(:mission_status, :client, steps: :step_status)
                             .order(created_at: :desc)
    @stats = {
      active:  @missions.count,
      clients: current_user.clients.count
    }
  end
end
