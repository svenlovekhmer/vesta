class Document < ApplicationRecord
  belongs_to :mission
  belongs_to :step, optional: true

  has_one_attached :file

  has_many :decision_log_documents, dependent: :destroy
  has_many :decision_logs, through: :decision_log_documents

  validates :name, presence: true
end
