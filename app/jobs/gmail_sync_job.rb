class GmailSyncJob < ApplicationJob
  queue_as :default

  def perform(client_id, mission_id, user_id)
    @client  = Client.find(client_id)
    @mission = Mission.find(mission_id)
    @user    = User.find(user_id)

    token    = @user.gmail_connection.fresh_access_token!
    messages = fetch_emails(token)

    if messages.empty?
      @client.update!(gmail_synthesis: nil, gmail_messages_count: 0, gmail_last_synced_at: Time.current)
      @mission.update!(last_synced_at: Time.current)
      broadcast_panel
      return
    end

    show_streaming_area
    synthesis = stream_synthesis(messages)
    result    = analyze_decisions(messages)

    @client.update!(
      gmail_synthesis: synthesis,
      gmail_messages_count: messages.count,
      gmail_last_synced_at: Time.current
    )

    @mission.update!(last_synced_at: Time.current)
    @mission.decision_logs.where(source: "gmail_ai").destroy_all
    (result["decided"] || []).compact.each_with_index do |item, i|
      @mission.decision_logs.create!(title: item["text"], owner_type: item["owner"],
                                     status: "decided", decided_at: Date.today,
                                     position: i, source: "gmail_ai")
    end
    (result["pending"] || []).compact.each_with_index do |item, i|
      @mission.decision_logs.create!(title: item["text"], owner_type: item["owner"],
                                     status: "pending", position: i, source: "gmail_ai")
    end

    broadcast_panel
  rescue StandardError => e
    Rails.logger.error("GmailSyncJob failed: #{e.message}")
    broadcast_pav_label_error
    if e.message.include?("token") || e.message.include?("invalid_request")
      broadcast_reconnect
    else
      broadcast_error(e.message)
    end
  end

  private

  def fetch_emails(token)
    query = "(from:#{@client.email} OR to:#{@client.email})"
    query += " after:#{@mission.last_synced_at.to_i}" if @mission.last_synced_at.present?

    list_resp = Faraday.get("https://gmail.googleapis.com/gmail/v1/users/me/messages") do |req|
      req.headers["Authorization"] = "Bearer #{token}"
      req.params["q"]          = query
      req.params["maxResults"] = 50
    end
    data        = JSON.parse(list_resp.body)
    message_ids = data["messages"]&.map { |m| m["id"] } || []

    message_ids.first(10).map do |mid|
      resp = Faraday.get("https://gmail.googleapis.com/gmail/v1/users/me/messages/#{mid}") do |req|
        req.headers["Authorization"] = "Bearer #{token}"
        req.params["format"]         = "full"
      end
      extract_message_data(JSON.parse(resp.body))
    end
  end

  def show_streaming_area
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_key,
      target: "gmail_synthesis_area_#{@client.id}",
      html: <<~HTML
        <div id="gmail_synthesis_area_#{@client.id}" class="mt-3 pt-3 border-top">
          <p class="fw-semibold mb-1 small text-muted text-uppercase" style="font-size:0.7rem;letter-spacing:0.05em;">Synthèse IA</p>
          <p class="small mb-0">
            <span id="gmail_synthesis_stream_#{@client.id}"></span><span class="gmail-cursor">▋</span>
          </p>
        </div>
      HTML
    )
  end

  def stream_synthesis(messages)
    synthesis = ""
    service   = build_service(messages)

    service.stream_synthesis do |token|
      synthesis += token
      Turbo::StreamsChannel.broadcast_append_to(
        stream_key,
        target: "gmail_synthesis_stream_#{@client.id}",
        html: token
      )
    end

    synthesis
  end

  def analyze_decisions(messages)
    build_service(messages).analyze_decisions
  end

  def build_service(messages)
    provider = @user.profile&.then { |p| "#{p.first_name} #{p.last_name}".strip } || @user.email
    GmailAnalysisService.new(messages, client_email: @client.email, provider_name: provider)
  end

  def broadcast_panel
    mission = @mission.reload

    Turbo::StreamsChannel.broadcast_replace_to(
      stream_key,
      target: "gmail_panel_#{mission.id}",
      html: ApplicationController.render(
        partial: "missions/gmail_panel",
        locals: { mission: mission, current_user: @user }
      )
    )

    all_logs     = mission.decision_logs.to_a
    pending      = all_logs.select { |dl| dl.status == "pending" }
    decided      = all_logs.select { |dl| dl.status == "decided" }
                           .sort_by { |dl| dl.decided_at || dl.created_at.to_date }
                           .reverse
    profile      = @user.profile

    Turbo::StreamsChannel.broadcast_replace_to(
      stream_key,
      target: "pav_section_#{mission.id}",
      html: ApplicationController.render(
        partial: "missions/pav_section",
        locals: {
          mission: mission,
          profile: profile,
          pending_logs: pending,
          vesta_count: pending.count { |dl| dl.owner_type == "provider" },
          client_count: pending.count { |dl| dl.owner_type == "client" }
        }
      )
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      stream_key,
      target: "decided_section_#{mission.id}",
      html: ApplicationController.render(
        partial: "missions/decided_section",
        locals: { mission: mission, profile: profile, decided_logs: decided }
      )
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      stream_key,
      target: "pav_sync_label_#{mission.id}",
      html: ApplicationController.render(
        partial: "dashboard/pav_sync_label",
        locals: { mission: mission, state: :fresh }
      )
    )
  end

  def broadcast_reconnect
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_key,
      target: "gmail_panel_#{@mission.id}",
      html: ApplicationController.render(
        partial: "missions/gmail_panel",
        locals: { mission: @mission.reload, current_user: @user, reconnect_needed: true }
      )
    )
  end

  def broadcast_error(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_key,
      target: "gmail_panel_#{@mission.id}",
      html: ApplicationController.render(
        partial: "missions/gmail_panel",
        locals: { mission: @mission.reload, current_user: @user, sync_error: message }
      )
    )
  end

  def broadcast_pav_label_error
    return unless @mission
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_key,
      target: "pav_sync_label_#{@mission.id}",
      html: ApplicationController.render(
        partial: "dashboard/pav_sync_label",
        locals: { mission: @mission, state: :error }
      )
    )
  rescue => e
    Rails.logger.error("broadcast_pav_label_error failed: #{e.message}")
  end

  def stream_key
    "gmail_sync_#{@mission.id}"
  end

  def extract_message_data(msg)
    headers = msg.dig("payload", "headers") || []
    {
      from:    headers.find { |h| h["name"] == "From" }&.dig("value"),
      date:    headers.find { |h| h["name"] == "Date" }&.dig("value"),
      subject: headers.find { |h| h["name"] == "Subject" }&.dig("value"),
      body:    extract_body(msg["payload"])
    }
  end

  def extract_body(payload)
    return "" unless payload

    if payload["body"]&.dig("data").present?
      Base64.urlsafe_decode64(payload["body"]["data"])
            .encode("UTF-8", invalid: :replace, undef: :replace)
            .gsub(/<[^>]+>/, " ").squish
    else
      (payload["parts"] || [])
        .filter_map { |p| extract_body(p) if p["mimeType"] == "text/plain" }
        .first || ""
    end
  end
end
