module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
    attr_reader :current_user
  end

  private

  def authenticate_request
    @current_user = authorize_request
  end

  def authorize_request
    header = request.headers['Authorization']
    return nil unless header.present?

    token = header.split(' ').last
    decoded = JsonWebToken.decode(token)
    return nil unless decoded

    User.find_by(id: decoded[:user_id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def require_authentication!
    unless @current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return false
    end
    true
  end

  def current_user_authorized?(user)
    @current_user&.id == user&.id
  end
end
