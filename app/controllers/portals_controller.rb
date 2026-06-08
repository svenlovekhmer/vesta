class PortalsController < ApplicationController
  def show
    @mission = Mission.find_by!(portal_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render file: "public/404.html", status: :not_found
  end
end
