module Api
  module V1
    class UsersController < ApplicationController
      include Authenticatable
      skip_before_action :authenticate_request, only: [:index, :show]
      before_action :set_user, only: [:show, :update, :destroy]
      before_action :require_authentication!, only: [:update, :destroy]
      before_action :check_authorization!, only: [:update, :destroy]

      def index
        users = User.all
        users = users.filter_by_status(params[:status]) if params[:status].present?
        users = users.page(params[:page]).per(params[:per_page] || 20)

        render json: { users: users.map(&:full_profile) }, status: :ok
      end

      def show
        render json: { user: @user.full_profile }, status: :ok
      end

      def update
        if @user.user_credential.update(credential_update_params) &&
           @user.user_profile.update(profile_update_params)
          render json: { user: @user.reload.full_profile }, status: :ok
        else
          render json: { errors: collect_errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @user.destroy
        head :no_content
      end

      private

      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end

      def check_authorization!
        unless current_user_authorized?(@user)
          render json: { error: 'Forbidden' }, status: :forbidden
        end
      end

      def credential_update_params
        params.fetch(:user, {}).permit(:email)
      end

      def profile_update_params
        params.fetch(:profile, {}).permit(:username, :bio, :avatar_url, :website_url, :birth_date)
      end

      def collect_errors
        errors = []
        errors += @user.user_credential.errors.full_messages
        errors += @user.user_profile.errors.full_messages
        errors
      end
    end
  end
end
