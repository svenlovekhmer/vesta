class PortalMailer < ApplicationMailer
  def send_link(mission)
    @mission = mission
    @portal_url = portal_url(token: mission.portal_token)
    mail(to: mission.client.email, subject: "Accès à votre espace mission")
  end
end
