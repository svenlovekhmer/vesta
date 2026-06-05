class MissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mission, only: %i[show destroy]
  before_action -> { add_breadcrumb "Tableau de bord", root_path }
  before_action -> { add_breadcrumb "Missions", missions_path }
  before_action -> { add_breadcrumb @mission.title }, only: [:show]
  before_action -> { add_breadcrumb "Nouvelle mission" }, only: %i[new create]

  def index
    @missions = current_user.missions.sort_by { |m| m.created_at }.reverse
  end

  def new
    @mission = Mission.new
    @clients = current_user.clients
    @step_templates = current_user.step_templates.includes(:step_template_items)
    @step_templates_json = build_templates_json(@step_templates)
    @default_template = current_user.step_templates.find_by(is_default: "true")
    preload_default_steps
  end

  def create
    @mission = Mission.new(mission_params)
    @mission.mission_status = MissionStatus.find_by(title: "En attente")
    if @mission.save
      save_steps_as_template
      redirect_to mission_path(@mission), notice: "La mission a été créée avec succès."
    else
      @clients = current_user.clients
      @step_templates = current_user.step_templates.includes(:step_template_items)
      @step_templates_json = build_templates_json(@step_templates)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @mission.destroy
    redirect_to missions_path, notice: "La mission a été supprimée."
  end

  def show
    pending = @mission.decision_logs.reverse.select { |dl| dl.status == "pending" }
    @pending_logs        = pending
    @vesta_pending_count = pending.count { |dl| dl.owner_type == "provider" }
    @client_pending_count = pending.count { |dl| dl.owner_type == "client" }

    @decided_logs = @mission.decision_logs
                            .select { |dl| dl.status == "decided" }
                            .sort_by { |dl| dl.decided_at || dl.created_at.to_date }
                            .reverse

    @step_statuses = StepStatus.all
    @documents = @mission.documents.with_attached_file.includes(:step).order(created_at: :desc)
  end

  private

  def set_mission
    @mission = current_user.missions
                           .includes(
                             :mission_status, :client,
                             steps: [:step_status, :documents, { mission_step_blockers: :decision_log }],
                             decision_logs: { mission_step_blockers: :step }
                           )
                           .find(params[:id])
  end

  def save_steps_as_template
    return if @mission.steps.empty?
    return if steps_match_existing_template?

    client = @mission.client
    template = current_user.step_templates.create!(
      name: "Modèle #{client.first_name} #{client.last_name}",
      is_default: "false"
    )

    @mission.steps.each do |step|
      template.step_template_items.create!(
        title: step.title,
        position: step.position.to_s
      )
    end
  end

  def steps_match_existing_template?
    step_titles = @mission.steps.map(&:title)
    current_user.step_templates.includes(:step_template_items).any? do |template|
      template.step_template_items.map(&:title) == step_titles
    end
  end

  def preload_default_steps
    default = current_user.step_templates.find_by(is_default: "true")
    return unless default

    default.step_template_items.each_with_index do |item, i|
      @mission.steps.build(title: item.title, position: i + 1)
    end
  end

  def build_templates_json(templates)
    templates.map do |t|
      { id: t.id, name: t.name,
        items: t.step_template_items.map { |i| { title: i.title } } }
    end.to_json
  end

  def mission_params
    params.require(:mission).permit(
      :title, :description, :client_id,
      steps_attributes: %i[id title position _destroy]
    )
  end
end
