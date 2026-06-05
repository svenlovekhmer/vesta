module ApplicationHelper
  def mission_status_badge(mission_status)
    slug = mission_status.title.parameterize
    tag.span("• #{mission_status.title}", class: "mission-badge mission-badge--#{slug}")
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
