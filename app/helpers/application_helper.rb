module ApplicationHelper
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
end
