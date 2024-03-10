# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :configure_permitted_parameters, only: [:create]
  def create
    super do |resource|
      render json: { message: "You have successfully logged in", user: resource }
      return
    end
  end

  def destroy
    super do |resource|
      render json: { message: "You have successfully logged out", user: resource }
      return
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in) do |user_params|
      user_params.permit(:email, :password)
    end
  end
end
