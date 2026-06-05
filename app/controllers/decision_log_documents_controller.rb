class DecisionLogDocumentsController < ApplicationController
  before_action :authenticate_user!

  def create
    mission_ids = current_user.missions.select(:id)
    @decision_log = DecisionLog.where(mission_id: mission_ids).find(params[:decision_log_id])
    @document = @decision_log.mission.documents.find(params[:document_id])

    DecisionLogDocument.find_or_create_by!(decision_log: @decision_log, document: @document)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
