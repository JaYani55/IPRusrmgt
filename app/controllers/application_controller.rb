class ApplicationController < ActionController::Base
  module SessionsHelper
    def log_in(user)
      session[:user_id] = user.id
    end

    def current_user
      @current_user ||= User.find_by(id: session[:user_id])
    end

    def logged_in?
      !current_user.nil?
    end

    # Other session-related methods...
  end

end
