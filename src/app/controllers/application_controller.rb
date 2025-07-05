class ApplicationController < ActionController::Base
  # Skip CSRF protection for API endpoints
  skip_before_action :verify_authenticity_token
end
