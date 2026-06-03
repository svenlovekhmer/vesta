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
    @client  = current_user.clients.find(params[:id])
    @mission = @client.missions.find(params[:mission_id])

    GmailSyncJob.perform_later(@client.id, @mission.id, current_user.id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "gmail_panel_#{@mission.id}",
          partial: "missions/gmail_panel_loading",
          locals: { mission: @mission }
        )
      end
      format.html { redirect_back fallback_location: client_path(@client) }
    end
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
