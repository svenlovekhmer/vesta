require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = User.create!(email: "sven@test.com",  password: "password123")
    @other = User.create!(email: "other@test.com", password: "password123")
  end

  # ── Accès ──────────────────────────────────────────────────────────────────

  test "un visiteur non connecté est redirigé vers la page de connexion" do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "un utilisateur connecté accède au tableau de bord" do
    sign_in @user
    get root_path
    assert_response :success
  end

  # ── Isolation des données ──────────────────────────────────────────────────

  test "les missions chargées appartiennent uniquement à l'utilisateur connecté" do
    my_mission    = create_mission_for(@user, title: "Ma mission")
    other_mission = create_mission_for(@other, title: "Mission d'un autre")

    sign_in @user
    get root_path

    assert_includes     assigns(:missions), my_mission
    assert_not_includes assigns(:missions), other_mission
  end

  test "un utilisateur sans mission voit une liste vide" do
    sign_in @user
    get root_path
    assert_empty assigns(:missions)
  end

  # ── Stats ──────────────────────────────────────────────────────────────────

  test "stats[:active] correspond au nombre de missions de l'utilisateur" do
    create_mission_for(@user, title: "Mission 1")
    create_mission_for(@user, title: "Mission 2")

    sign_in @user
    get root_path

    assert_equal 2, assigns(:stats)[:active]
  end

  test "stats[:clients] correspond au nombre de clients de l'utilisateur" do
    create_mission_for(@user)
    create_mission_for(@user)

    sign_in @user
    get root_path

    assert_equal 2, assigns(:stats)[:clients]
  end

  test "les stats ne comptent pas les missions ou clients d'autres utilisateurs" do
    create_mission_for(@user)
    create_mission_for(@other)

    sign_in @user
    get root_path

    assert_equal 1, assigns(:stats)[:active]
    assert_equal 1, assigns(:stats)[:clients]
  end

  # ── Ordre ──────────────────────────────────────────────────────────────────

  test "les missions sont triées de la plus récente à la plus ancienne" do
    older  = create_mission_for(@user, title: "Ancienne",  created_at: 1.week.ago)
    recent = create_mission_for(@user, title: "Récente",   created_at: 1.day.ago)

    sign_in @user
    get root_path

    assert_equal recent, assigns(:missions).first
    assert_equal older,  assigns(:missions).last
  end

  # ── Eager loading ──────────────────────────────────────────────────────────

  test "la page affiche tous les titres de missions" do
    create_mission_for(@user, title: "Mission Alpha")
    create_mission_for(@user, title: "Mission Beta")

    sign_in @user
    get root_path

    assert_match "Mission Alpha", response.body
    assert_match "Mission Beta",  response.body
  end
end
