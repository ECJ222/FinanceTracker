# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters, if: :devise_controller?

  def create
    super do |resource|
      render json: { message: "User sign up was successful", user: resource }
      return
    end
  end

  protected


  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |user_params|
      user_params.permit(:first_name, :last_name, :email, :password)
    end
  end
end