class StepTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_step_template, only: %i[edit update destroy confirm_destroy]
  before_action -> { add_breadcrumb "Tableau de bord", root_path }
  before_action -> { add_breadcrumb "Templates", step_templates_path }
  before_action -> { add_breadcrumb @step_template.name }, only: %i[edit confirm_destroy]
  before_action -> { add_breadcrumb "Modifier" }, only: [:edit]
  before_action -> { add_breadcrumb "Nouveau template" }, only: %i[new create]

  def index
    @step_templates = current_user.step_templates.includes(:step_template_items)
  end

  def new
    @step_template = current_user.step_templates.build
  end

  def create
    @step_template = current_user.step_templates.build(step_template_params)
    if @step_template.save
      redirect_to step_templates_path, notice: "Template créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @step_template.update(step_template_params)
      redirect_to step_templates_path, notice: "Template mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @step_template.destroy
    redirect_to step_templates_path, notice: "Template supprimé avec succès."
  end

  def confirm_destroy
  end

  private

  def set_step_template
    @step_template = current_user.step_templates.find(params[:id])
  end

  def step_template_params
    params.require(:step_template).permit(
      :name, :description, :is_default,
      step_template_items_attributes: %i[id title description position _destroy]
    )
  end
end
