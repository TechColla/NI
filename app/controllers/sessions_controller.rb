 
class SessionsController < Devise::SessionsController

  rescue_from OpenSSL::SSL::SSLError do |exception|
    redirect_to uk_login_path, :alert => "Sorry, the UK server isn't currently available."
  end

  # this is to allow the ios app to log in (and get the csrf token) even if it is already logged in
  skip_before_filter :require_no_authentication, only: [:create]
  # this stops the warning about no csrf token on /users/sign_in
  skip_before_filter :verify_authenticity_token, only: [:create]

  before_filter :set_csrf_token_header, only: [:create]

  def create
    # Login attempts now try the database strategy, then the remote UK authentication strategy.
    warden.config[:default_strategies][:user].push(warden.config[:default_strategies][:user].shift)
    self.resource = warden.authenticate!(auth_options)
    super
  end

  def new_uk
    # Custom sign-in path /uk_login for UK subscribers
  end

  def after_sign_in_path_for(new_uk)
    # After successfully logging in, redirect UK users here
    root_path
  end

  private

  def set_csrf_token_header 
    if request.format == "application/json"
      response.headers["X-CSRF-Token"] = form_authenticity_token
    end
  end

end
