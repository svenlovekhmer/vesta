require "test_helper"

class MissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = User.create!(email: "sven@test.com",  password: "password123")
    @other = User.create!(email: "other@test.com", password: "password123")
    MissionStatus.find_or_create_by!(title: "En attente")
  end

  # ── Accès ──────────────────────────────────────────────────────────────────

  test "un visiteur non connecté est redirigé vers la page de connexion sur index" do
    get missions_path
    assert_redirected_to new_user_session_path
  end

  test "un visiteur non connecté est redirigé vers la page de connexion sur new" do
    get new_mission_path
    assert_redirected_to new_user_session_path
  end

  test "un visiteur non connecté est redirigé vers la page de connexion sur create" do
    post missions_path, params: { mission: { title: "Test" } }
    assert_redirected_to new_user_session_path
  end

  test "un visiteur non connecté est redirigé vers la page de connexion sur show" do
    mission = create_mission_for(@user)
    get mission_path(mission)
    assert_redirected_to new_user_session_path
  end

  # ── Index ──────────────────────────────────────────────────────────────────

  test "un utilisateur connecté accède à la liste des missions" do
    sign_in @user
    get missions_path
    assert_response :success
  end

  test "index ne charge que les missions de l'utilisateur connecté" do
    my_mission    = create_mission_for(@user,  title: "Ma mission")
    other_mission = create_mission_for(@other, title: "Mission d'un autre")

    sign_in @user
    get missions_path

    assert_includes     assigns(:missions), my_mission
    assert_not_includes assigns(:missions), other_mission
  end

  test "index retourne une liste vide pour un utilisateur sans mission" do
    sign_in @user
    get missions_path
    assert_empty assigns(:missions)
  end

  # ── New ────────────────────────────────────────────────────────────────────

  test "new répond avec succès pour un utilisateur connecté" do
    sign_in @user
    get new_mission_path
    assert_response :success
  end

  test "new initialise une nouvelle mission vide" do
    sign_in @user
    get new_mission_path
    assert assigns(:mission).new_record?
  end

  test "new charge uniquement les clients de l'utilisateur connecté" do
    my_client    = Client.create!(user: @user,  first_name: "Alice", last_name: "A", email: "alice@test.com")
    other_client = Client.create!(user: @other, first_name: "Bob",   last_name: "B", email: "bob@test.com")

    sign_in @user
    get new_mission_path

    assert_includes     assigns(:clients), my_client
    assert_not_includes assigns(:clients), other_client
  end

  # ── Create ─────────────────────────────────────────────────────────────────

  test "create avec des paramètres valides crée une mission et redirige vers show" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice@test.com")

    sign_in @user
    assert_difference("Mission.count", 1) do
      post missions_path, params: { mission: { title: "Nouvelle mission", client_id: client.id } }
    end

    assert_redirected_to mission_path(Mission.last)
    assert_equal "La mission a été créée avec succès.", flash[:notice]
  end

  test "create assigne automatiquement le statut 'En attente'" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice@test.com")

    sign_in @user
    post missions_path, params: { mission: { title: "Nouvelle mission", client_id: client.id } }

    assert_equal "En attente", Mission.last.mission_status.title
  end

  test "create avec un titre manquant affiche le formulaire avec une erreur" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice@test.com")

    sign_in @user
    assert_no_difference("Mission.count") do
      post missions_path, params: { mission: { title: "", client_id: client.id } }
    end

    assert_response :unprocessable_entity
    assert_not_nil assigns(:clients)
  end

  test "create avec un client_id manquant affiche le formulaire avec une erreur" do
    sign_in @user
    assert_no_difference("Mission.count") do
      post missions_path, params: { mission: { title: "Mission sans client" } }
    end

    assert_response :unprocessable_entity
  end

  # ── Show ───────────────────────────────────────────────────────────────────

  test "show répond avec succès pour une mission appartenant à l'utilisateur" do
    mission = create_mission_for(@user, title: "Ma mission")

    sign_in @user
    get mission_path(mission)

    assert_response :success
    assert_equal mission, assigns(:mission)
  end

  test "show répond 404 pour une mission appartenant à un autre utilisateur" do
    other_mission = create_mission_for(@other, title: "Mission d'un autre")

    sign_in @user
    get mission_path(other_mission)

    assert_response :not_found
  end
end
