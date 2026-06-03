class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client, only: %i[show edit update destroy confirm_destroy]
  before_action -> { add_breadcrumb "Tableau de bord", root_path }
  before_action -> { add_breadcrumb "Clients", clients_path }
  before_action -> { add_breadcrumb "#{@client.first_name} #{@client.last_name}" },
                only: %i[show edit confirm_destroy]
  before_action -> { add_breadcrumb "Modifier" }, only: [:edit]
  before_action -> { add_breadcrumb "Nouveau client" }, only: %i[new create]

  def index
    @clients = current_user.clients
  end

  def show
  end

  def new
    @client = current_user.clients.build
  end

  def create
    @client = current_user.clients.build(client_params)
    if @client.save
      redirect_to clients_path, notice: "Client créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def sync_emails
    @client = current_user.clients.find(params[:id])

    query = "(from:#{@client.email} OR to:#{@client.email})"

    response = Faraday.get(
      "https://gmail.googleapis.com/gmail/v1/users/me/messages"
    ) do |req|
      req.headers["Authorization"] = "Bearer #{current_user.gmail_connection.access_token}"
      req.params["q"] = query
      req.params["format"] = "full"
      req.params["maxResults"] = 50
    end

    data = JSON.parse(response.body)
    messages_count = data["messages"]&.count || 0

    if data["messages"].present?
      message_id = data["messages"].first["id"]

      message_response = Faraday.get(
        "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{message_id}"
      ) do |req|
        req.headers["Authorization"] = "Bearer #{current_user.gmail_connection.access_token}"
        req.params["format"] = "full"
      end

      data["first_message"] = JSON.parse(message_response.body)
    end

    @client.update!(
      gmail_summary: JSON.pretty_generate(data),
      gmail_messages_count: messages_count,
      gmail_last_synced_at: Time.current
    )

    redirect_back fallback_location: client_path(@client), notice: "Emails synchronisés."
  end

  def edit
  end

  def update
    if @client.update(client_params)
      respond_with_updated_client
    else
      respond_with_client_errors
    end
  end

  def destroy
    @client.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("client_#{@client.id}"),
          turbo_stream.update("modal", "")
        ]
      end
      format.html { redirect_to clients_path, notice: "Client supprimé avec succès." }
    end
  end

  def confirm_destroy
  end

  private

  def respond_with_updated_client
    respond_to do |format|
      format.turbo_stream { render turbo_stream: updated_client_streams }
      format.html { redirect_to clients_path, notice: "Client mis à jour avec succès." }
    end
  end

  def respond_with_client_errors
    respond_to do |format|
      format.turbo_stream { render turbo_stream: client_form_error_stream }
      format.html { render :edit, status: :unprocessable_entity }
    end
  end

  def updated_client_streams
    [
      turbo_stream.replace("client_#{@client.id}",
                           partial: "clients/client_card", locals: { client: @client }),
      turbo_stream.update("modal", "")
    ]
  end

  def client_form_error_stream
    turbo_stream.update("modal",
                        partial: "clients/modal_form", locals: { client: @client })
  end

  def set_client
    @client = current_user.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:first_name, :last_name, :email, :phone_number)
  end
end
