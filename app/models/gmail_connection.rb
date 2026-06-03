class GmailConnection < ApplicationRecord
  belongs_to :user

  validates :email, uniqueness: true

  GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"

  def fresh_access_token!
    refresh! if token_expired?
    access_token
  end

  private

  def token_expired?
    expires_at.present? && expires_at <= Time.current + 30.seconds
  end

  def refresh!
    response = Faraday.post(GOOGLE_TOKEN_URL,
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      refresh_token: refresh_token,
      grant_type: "refresh_token")

    data = JSON.parse(response.body)
    raise "Gmail token refresh failed: #{data['error']}" if data["error"].present?

    update!(
      access_token: data["access_token"],
      expires_at: Time.current + data["expires_in"].to_i.seconds
    )
  end
end
