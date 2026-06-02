class StepTemplate < ApplicationRecord
  belongs_to :user
  has_many :step_template_items, -> { order(Arel.sql("position::integer")) }, dependent: :destroy
end
