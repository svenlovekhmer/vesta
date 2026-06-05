require "test_helper"

class MissionTest < ActiveSupport::TestCase
  setup do
    @user   = User.create!(email: "mission_test@test.com", password: "password123")
    @status = MissionStatus.find_or_create_by!(title: "À démarrer")
    @client = Client.create!(user: @user, first_name: "Alice", last_name: "Test", email: "alice_mt@test.com", phone_number: "0600000000")
    @template = StepTemplate.create!(user: @user, name: "Tpl", description: "D")
    StepStatus.find_or_create_by!(title: "À faire")
  end

  def build_mission(attrs = {})
    Mission.new({
      title: "Mission test",
      mission_status: @status,
      client: @client,
      step_template: @template,
      portal_token: SecureRandom.hex(10)
    }.merge(attrs))
  end

  # ── accepts_nested_attributes_for ──────────────────────────────────────────

  test "crée les étapes via steps_attributes" do
    mission = build_mission(steps_attributes: [
      { title: "Étape 1", position: 1 },
      { title: "Étape 2", position: 2 }
    ])
    assert_difference("Step.count", 2) { mission.save! }
    assert_equal 2, mission.steps.count
  end

  test "reject_if all_blank ignore les lignes entièrement vides" do
    mission = build_mission(steps_attributes: [
      { title: "", position: "" }
    ])
    assert_difference("Step.count", 0) { mission.save! }
  end

  test "les étapes sont retournées triées par position" do
    mission = build_mission(steps_attributes: [
      { title: "C", position: 3 },
      { title: "A", position: 1 },
      { title: "B", position: 2 }
    ])
    mission.save!
    assert_equal %w[A B C], mission.steps.map(&:title)
  end

  test "_destroy supprime une étape existante lors de la mise à jour" do
    mission = build_mission(steps_attributes: [{ title: "À supprimer", position: 1 }])
    mission.save!
    step = mission.steps.first

    assert_difference("Step.count", -1) do
      mission.update!(steps_attributes: [{ id: step.id, _destroy: "1" }])
    end
  end
end
