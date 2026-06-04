class DocumentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @mission = current_user.missions.find(params[:mission_id])
    files = Array(params.dig(:document, :files)).select(&:present?)
    step_id = params.dig(:document, :step_id).presence

    files.each do |file|
      name = File.basename(file.original_filename, ".*")
      doc = @mission.documents.build(name: name, step_id: step_id)
      doc.file.attach(file)
      doc.save
    end

    @documents = @mission.documents.with_attached_file.includes(:step).order(created_at: :desc)
    respond_to { |f| f.turbo_stream }
  end

  def destroy
    mission_ids = current_user.missions.select(:id)
    @document = Document.joins(:mission)
                        .where(missions: { id: mission_ids })
                        .find(params[:id])
    @mission = @document.mission
    @document.destroy
    @documents = @mission.documents.with_attached_file.includes(:step).order(created_at: :desc)
    respond_to { |f| f.turbo_stream }
  end
end
