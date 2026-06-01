require "application_system_test_case"

class DashboardSystemTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(email: "sven@test.com", password: "password123")
    Profile.create!(
      user: @user,
      first_name: "Sven",
      last_name: "Dupont",
      profession: "Architecte d'intérieur"
    )

    @mission_en_cours = create_mission_for(@user, title: "Refonte site",    status_title: "En cours")
    @mission_terminee = create_mission_for(@user, title: "Audit SEO terminé", status_title: "Terminée")

    # Ajouter des steps à la mission terminée pour avoir 100% de progression
    step_status_validee = StepStatus.find_or_create_by!(title: "Validée")
    Step.create!(title: "Étape 1", position: 1, mission: @mission_terminee, step_status: step_status_validee)

    login_as @user
  end

  # ── Contenu affiché ────────────────────────────────────────────────────────

  test "affiche le titre de la page" do
    assert_text "Tableau de bord"
  end

  test "affiche les titres de toutes les missions" do
    assert_text "Refonte site"
    assert_text "Audit SEO terminé"
  end

  test "affiche le badge de statut pour chaque mission" do
    assert_text "En cours"
    assert_text "Terminée"
  end

  test "affiche les stats du tableau de bord" do
    # 2 missions, 2 clients
    within(".stat-card", match: :first) do
      assert_text "2"
    end
  end

  test "affiche le prénom de l'utilisateur dans le sous-titre" do
    assert_text "Bonjour Sven"
  end

  # ── Sidebar ────────────────────────────────────────────────────────────────

  test "la sidebar affiche le nom et la profession" do
    within(".app-sidebar") do
      assert_text "Sven Dupont"
      assert_text "Architecte d'intérieur"
    end
  end

  test "la sidebar affiche le logo VESTA" do
    within(".app-sidebar") do
      assert_text "VESTA"
    end
  end

  # ── Filtres par onglet (Stimulus) ──────────────────────────────────────────

  test "l'onglet Terminées masque les missions non terminées" do
    click_button "Terminées"

    assert_text    "Audit SEO terminé"
    assert_no_text "Refonte site"
  end

  test "l'onglet En cours masque les missions terminées" do
    click_button "En cours"

    assert_text    "Refonte site"
    assert_no_text "Audit SEO terminé"
  end

  test "l'onglet Toutes réaffiche toutes les missions" do
    click_button "Terminées"
    click_button "Toutes"

    assert_text "Refonte site"
    assert_text "Audit SEO terminé"
  end

  # ── Progress bar ───────────────────────────────────────────────────────────

  test "la progression de la mission terminée est 100%" do
    assert_text "100%"
  end
end
