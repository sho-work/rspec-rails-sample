module Api
  module V1
    class AuthController < ApplicationController
      include Authenticatable
      skip_before_action :authenticate_request, only: [:signup, :login]

      def signup
        user = User.new
        user.build_user_credential(credential_params)
        user.build_user_profile(profile_params)

        if user.save
          UserStatus.create_initial_status(user)
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: user.full_profile }, status: :created
        else
          render json: { errors: collect_errors(user) }, status: :unprocessable_entity
        end
      end

      def login
        credential = UserCredential.find_by(email: params[:email])

        if credential&.authenticate_with_lock(params[:password])
          if credential.user.can_login?
            token = JsonWebToken.encode(user_id: credential.user.id)
            render json: { token: token, user: credential.user.full_profile }, status: :ok
          else
            render json: { error: 'Account is suspended or deleted' }, status: :forbidden
          end
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end

      def logout
        return unless require_authentication!
        head :no_content
      end

      def me
        return unless require_authentication!
        render json: { user: @current_user.full_profile }, status: :ok
      end

      private

      def credential_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end

      def profile_params
        params.require(:user).permit(:username, :bio)
      end

      def collect_errors(user)
        errors = user.errors.full_messages
        errors += user.user_credential.errors.full_messages if user.user_credential
        errors += user.user_profile.errors.full_messages if user.user_profile
        errors
      end
    end
  end
end
