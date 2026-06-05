class Mission < ApplicationRecord
  belongs_to :mission_status
  belongs_to :step_template, optional: true # temporary, to be removed when the step templatating will be implemented
  belongs_to :client

  has_many :steps, -> { order(:position) }, dependent: :destroy
  has_many :decision_logs, dependent: :destroy
  has_many :mission_step_blockers, dependent: :destroy
  has_many :documents, dependent: :destroy

  accepts_nested_attributes_for :steps, allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true

  def auto_update_status!
    statuses = steps.map { |s| s.step_status.title }
    new_status_title = if statuses.all? { |t| t == "À faire" }
                         "En attente"
                       elsif statuses.all? { |t| t == "Validée" }
                         "Terminée"
                       else
                         "En cours"
                       end
    new_status = MissionStatus.find_by!(title: new_status_title)
    update!(mission_status: new_status) unless mission_status == new_status
  end

  def last_activity_at
    timestamps = [updated_at] + steps.map(&:updated_at) + decision_logs.map(&:updated_at)
    timestamps.compact.max
  end
end
