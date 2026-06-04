module ApplicationHelper
  def mission_status_badge(mission_status)
    title = mission_status.title
    icon_html = case title
                when "En cours"    then tag.i(class: "fa-solid fa-circle text-success me-2")
                when "En attente"  then tag.i(class: "fa-solid fa-circle text-danger me-2")
                when "Terminée"    then tag.i(class: "fa-solid fa-circle-check text-success me-2")
                end
    safe_join([icon_html, title])
  end

  def user_initials(user)
    profile = user.profile
    if profile&.first_name.present? && profile&.last_name.present?
      "#{profile.first_name[0]}#{profile.last_name[0]}".upcase
    else
      user.email[0..1].upcase
    end
  end

  def user_display_name(user)
    profile = user.profile
    if profile&.first_name.present? && profile&.last_name.present?
      "#{profile.first_name} #{profile.last_name}"
    else
      user.email
    end
  end

  def format_date_fr(date)
    months = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre]
    "#{date.day} #{months[date.month - 1]}"
  end
end
