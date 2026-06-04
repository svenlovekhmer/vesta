class Step < ApplicationRecord
  belongs_to :step_status
  belongs_to :mission

  has_many :mission_step_blockers, dependent: :destroy

  before_validation :assign_default_status
  validates :title, presence: true

  private

  def assign_default_status
    self.step_status ||= StepStatus.find_by(title: "À faire")
  end
end
