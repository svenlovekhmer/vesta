module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # skip_before_action :authenticate_user!

    def google_oauth2
      if current_user.present?
        connect_gmail_to_current_user
      else
        login_or_signup_with_google
      end
    end

    protected

    def after_omniauth_failure_path_for(_scope)
      new_user_session_path
    end

    def after_sign_in_path_for(resource_or_scope)
      stored_location_for(resource_or_scope) || root_path
    end

    private

    def update_gmail_connection!(gmail_connection, user)
      gmail_connection.user = user
      gmail_connection.assign_attributes(
        email: auth.info.email,
        access_token: auth.credentials.token,
        expires_at: auth.credentials.expires_at.present? ? Time.at(auth.credentials.expires_at) : nil
      )
      gmail_connection.refresh_token = auth.credentials.refresh_token if auth.credentials.refresh_token.present?
      gmail_connection.save!
    end

    def connect_gmail_to_current_user
      gmail_connection = current_user.gmail_connection || current_user.build_gmail_connection
      update_gmail_connection!(gmail_connection, current_user)
      redirect_to root_path, notice: "Gmail connecté avec succès."
    end

    def login_or_signup_with_google
      existing_connection = GmailConnection.find_by(email: auth.info.email)

      user =
        if existing_connection.present?
          existing_connection.user
        else
          User.from_omniauth(auth)
        end

      user.save! if user.new_record?

      save_gmail_connection_for(user)

      sign_out_all_scopes
      flash[:success] = t("devise.omniauth_callbacks.success", kind: "Google")
      sign_in_and_redirect user, event: :authentication
    end

    def save_gmail_connection_for(user)
      gmail_connection =
        GmailConnection.find_by(email: auth.info.email) ||
        user.gmail_connection ||
        user.build_gmail_connection

      update_gmail_connection!(gmail_connection, user)
    end

    def auth
      @auth ||= request.env["omniauth.auth"]
    end
  end
end
