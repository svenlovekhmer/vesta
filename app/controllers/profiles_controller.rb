class ProfilesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_profile

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to edit_profile_path, notice: "Profil mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.profile || current_user.build_profile
  end

  def profile_params
    params.require(:profile).permit(:first_name, :last_name, :profession, :logo)
  end
end
