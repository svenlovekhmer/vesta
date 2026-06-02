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
    my_client    = Client.create!(user: @user,  first_name: "Alice", last_name: "A", email: "alice@test.com", phone_number: "0600000000")
    other_client = Client.create!(user: @other, first_name: "Bob",   last_name: "B", email: "bob@test.com", phone_number: "0600000000")

    sign_in @user
    get new_mission_path

    assert_includes     assigns(:clients), my_client
    assert_not_includes assigns(:clients), other_client
  end

  # ── Create ─────────────────────────────────────────────────────────────────

  test "create avec des paramètres valides crée une mission et redirige vers show" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice@test.com", phone_number: "0600000000")

    sign_in @user
    assert_difference("Mission.count", 1) do
      post missions_path, params: { mission: { title: "Nouvelle mission", client_id: client.id } }
    end

    assert_redirected_to mission_path(Mission.last)
    assert_equal "La mission a été créée avec succès.", flash[:notice]
  end

  test "create assigne automatiquement le statut 'En attente'" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice@test.com", phone_number: "0600000000")

    sign_in @user
    post missions_path, params: { mission: { title: "Nouvelle mission", client_id: client.id } }

    assert_equal "En attente", Mission.last.mission_status.title
  end

  test "create avec un titre manquant affiche le formulaire avec une erreur" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice@test.com", phone_number: "0600000000")

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

  # ── Steps — New ────────────────────────────────────────────────────────────

  test "new expose les modèles d'étapes de l'utilisateur connecté" do
    my_template    = StepTemplate.create!(user: @user,  name: "Mon modèle",  description: "D")
    other_template = StepTemplate.create!(user: @other, name: "Autre modèle", description: "D")

    sign_in @user
    get new_mission_path

    assert_includes     assigns(:step_templates), my_template
    assert_not_includes assigns(:step_templates), other_template
  end

  test "new expose le JSON des modèles d'étapes" do
    StepTemplate.create!(user: @user, name: "Modèle A", description: "D")

    sign_in @user
    get new_mission_path

    assert_not_nil assigns(:step_templates_json)
    parsed = JSON.parse(assigns(:step_templates_json))
    assert_equal 1, parsed.length
    assert_equal "Modèle A", parsed.first["name"]
  end

  # ── Steps — Create ─────────────────────────────────────────────────────────

  test "create avec steps_attributes crée les étapes associées à la mission" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice_sc@test.com", phone_number: "0600000000")
    StepStatus.find_or_create_by!(title: "À faire")

    sign_in @user
    assert_difference("Step.count", 2) do
      post missions_path, params: {
        mission: {
          title: "Mission avec étapes",
          client_id: client.id,
          steps_attributes: {
            "0" => { title: "Étude préalable", position: "1" },
            "1" => { title: "Permis de construire", position: "2" }
          }
        }
      }
    end
  end

  test "les étapes créées reçoivent automatiquement le statut 'À faire'" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice_sf@test.com", phone_number: "0600000000")
    StepStatus.find_or_create_by!(title: "À faire")

    sign_in @user
    post missions_path, params: {
      mission: {
        title: "Mission statut étapes",
        client_id: client.id,
        steps_attributes: { "0" => { title: "Première étape", position: "1" } }
      }
    }

    step = Mission.last.steps.first
    assert_equal "À faire", step.step_status.title
  end

  test "les étapes créées ont les positions soumises par le formulaire" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice_sp@test.com", phone_number: "0600000000")
    StepStatus.find_or_create_by!(title: "À faire")

    sign_in @user
    post missions_path, params: {
      mission: {
        title: "Mission positions étapes",
        client_id: client.id,
        steps_attributes: {
          "0" => { title: "Étape A", position: "1" },
          "1" => { title: "Étape B", position: "2" }
        }
      }
    }

    steps = Mission.last.steps
    assert_equal [1, 2], steps.map(&:position)
  end

  test "create avec une étape au titre vide ne crée pas cette étape" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice_sb@test.com", phone_number: "0600000000")

    sign_in @user
    assert_difference("Step.count", 0) do
      post missions_path, params: {
        mission: {
          title: "Mission sans étape",
          client_id: client.id,
          steps_attributes: { "0" => { title: "", position: "" } }
        }
      }
    end
  end

  test "create sauvegarde les étapes comme nouveau template nommé d'après le client" do
    client = Client.create!(user: @user, first_name: "Marie", last_name: "Laurent", email: "ml_tpl@test.com", phone_number: "0600000000")
    StepStatus.find_or_create_by!(title: "À faire")

    sign_in @user
    assert_difference("StepTemplate.count", 1) do
      post missions_path, params: {
        mission: {
          title: "Mission Marie",
          client_id: client.id,
          steps_attributes: {
            "0" => { title: "Brief reçu", position: "1" },
            "1" => { title: "Visite réalisée", position: "2" }
          }
        }
      }
    end

    template = StepTemplate.order(:created_at).last
    assert_equal "Modèle Marie Laurent", template.name
    assert_equal %w[Brief\ reçu Visite\ réalisée], template.step_template_items.map(&:title)
  end

  test "create ne sauvegarde pas un template si les étapes sont identiques à un template existant" do
    client = Client.create!(user: @user, first_name: "Marie", last_name: "Laurent", email: "ml_dup@test.com", phone_number: "0600000000")
    StepStatus.find_or_create_by!(title: "À faire")

    existing = StepTemplate.create!(user: @user, name: "Modèle existant", is_default: "false")
    StepTemplateItem.create!(step_template: existing, title: "Brief reçu",    position: "1")
    StepTemplateItem.create!(step_template: existing, title: "Visite réalisée", position: "2")

    sign_in @user
    assert_no_difference("StepTemplate.count") do
      post missions_path, params: {
        mission: {
          title: "Mission Marie",
          client_id: client.id,
          steps_attributes: {
            "0" => { title: "Brief reçu",    position: "1" },
            "1" => { title: "Visite réalisée", position: "2" }
          }
        }
      }
    end
  end

  test "create sauvegarde un nouveau template si l'ordre des étapes a changé" do
    client = Client.create!(user: @user, first_name: "Marie", last_name: "Laurent", email: "ml_reorder@test.com", phone_number: "0600000000")
    StepStatus.find_or_create_by!(title: "À faire")

    existing = StepTemplate.create!(user: @user, name: "Modèle existant", is_default: "false")
    StepTemplateItem.create!(step_template: existing, title: "Brief reçu",    position: "1")
    StepTemplateItem.create!(step_template: existing, title: "Visite réalisée", position: "2")

    sign_in @user
    assert_difference("StepTemplate.count", 1) do
      post missions_path, params: {
        mission: {
          title: "Mission Marie",
          client_id: client.id,
          steps_attributes: {
            "0" => { title: "Visite réalisée", position: "1" },
            "1" => { title: "Brief reçu",      position: "2" }
          }
        }
      }
    end
  end

  test "create sans étapes ne crée pas de template" do
    client = Client.create!(user: @user, first_name: "Alice", last_name: "A", email: "alice_notpl@test.com", phone_number: "0600000000")

    sign_in @user
    assert_no_difference("StepTemplate.count") do
      post missions_path, params: {
        mission: { title: "Mission sans étapes", client_id: client.id }
      }
    end
  end

  test "create en échec re-expose les modèles d'étapes" do
    StepTemplate.create!(user: @user, name: "Modèle B", description: "D")

    sign_in @user
    post missions_path, params: { mission: { title: "" } }

    assert_response :unprocessable_entity
    assert_not_nil assigns(:step_templates)
    assert_not_nil assigns(:step_templates_json)
  end
end
