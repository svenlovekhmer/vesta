require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "sven@test.com", password: "password123")
  end

  # ── Accès ──────────────────────────────────────────────────────────────────

  test "un visiteur non connecté est redirigé vers la page de connexion sur edit" do
    get edit_profile_path
    assert_redirected_to new_user_session_path
  end

  test "un visiteur non connecté est redirigé vers la page de connexion sur update" do
    patch profile_path, params: { profile: { first_name: "Alice" } }
    assert_redirected_to new_user_session_path
  end

  # ── Edit ───────────────────────────────────────────────────────────────────

  test "edit répond avec succès pour un utilisateur connecté" do
    sign_in @user
    get edit_profile_path
    assert_response :success
  end

  test "edit initialise un profil vide si l'utilisateur n'en a pas" do
    sign_in @user
    get edit_profile_path
    assert assigns(:profile).new_record?
  end

  test "edit charge le profil existant si l'utilisateur en a déjà un" do
    profile = Profile.create!(user: @user, first_name: "Sven", last_name: "Dupont")
    sign_in @user
    get edit_profile_path
    assert_equal profile, assigns(:profile)
  end

  # ── Update ─────────────────────────────────────────────────────────────────

  test "update crée un profil si l'utilisateur n'en a pas encore" do
    sign_in @user
    assert_difference("Profile.count", 1) do
      patch profile_path, params: { profile: { first_name: "Alice", last_name: "Martin" } }
    end
  end

  test "update met à jour un profil existant sans en créer un nouveau" do
    Profile.create!(user: @user, first_name: "Sven", last_name: "Dupont")
    sign_in @user
    assert_no_difference("Profile.count") do
      patch profile_path, params: { profile: { first_name: "Alice", last_name: "Martin" } }
    end
    assert_equal "Alice", @user.profile.reload.first_name
    assert_equal "Martin", @user.profile.last_name
  end

  test "update avec des paramètres valides redirige vers edit avec un message de succès" do
    sign_in @user
    patch profile_path, params: { profile: { first_name: "Alice", last_name: "Martin" } }
    assert_redirected_to edit_profile_path
    assert_equal "Profil mis à jour avec succès.", flash[:notice]
  end

  test "update accepte un profil avec des champs vides (aucun champ requis)" do
    sign_in @user
    patch profile_path, params: { profile: { first_name: "", last_name: "" } }
    assert_redirected_to edit_profile_path
  end

  test "update ignore les paramètres non autorisés" do
    sign_in @user
    patch profile_path, params: { profile: { first_name: "Alice", profession: "Architecte" } }
    assert_nil @user.profile.reload.profession
  end
end
