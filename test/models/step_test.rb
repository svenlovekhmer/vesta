require "test_helper"

class StepTest < ActiveSupport::TestCase
  setup do
    @user    = User.create!(email: "step_test@test.com", password: "password123")
    @mission = create_mission_for(@user, title: "Mission pour étapes")
    StepStatus.find_or_create_by!(title: "À faire")
    StepStatus.find_or_create_by!(title: "En cours")
  end

  # ── Validation ─────────────────────────────────────────────────────────────

  test "une étape sans titre est invalide" do
    step = Step.new(mission: @mission, title: "")
    assert_not step.valid?
    assert_includes step.errors[:title], "can't be blank"
  end

  test "une étape avec titre est valide" do
    step = Step.new(mission: @mission, title: "Étude préalable")
    assert step.valid?
  end

  # ── Statut par défaut ──────────────────────────────────────────────────────

  test "before_validation assigne le statut 'À faire' si aucun statut n'est défini" do
    step = Step.new(mission: @mission, title: "Nouvelle étape")
    step.valid?
    assert_equal "À faire", step.step_status.title
  end

  test "before_validation ne remplace pas un statut explicitement défini" do
    en_cours = StepStatus.find_by!(title: "En cours")
    step = Step.new(mission: @mission, title: "Étape en cours", step_status: en_cours)
    step.valid?
    assert_equal "En cours", step.step_status.title
  end

  test "create persiste l'étape avec le statut 'À faire' par défaut" do
    step = Step.create!(mission: @mission, title: "Démarrage", position: 1)
    assert_equal "À faire", step.reload.step_status.title
  end
end
