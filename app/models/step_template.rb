class StepTemplate < ApplicationRecord
  belongs_to :user
  has_many :step_template_items, -> { order(Arel.sql("position::integer")) }, dependent: :destroy
  accepts_nested_attributes_for :step_template_items, allow_destroy: true, reject_if: :all_blank
end
