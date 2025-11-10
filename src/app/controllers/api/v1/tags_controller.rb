module Api
  module V1
    class TagsController < ApplicationController
      include Authenticatable
      skip_before_action :authenticate_request, only: [:index, :show]
      before_action :require_authentication!, only: [:create, :update, :destroy]
      before_action :set_tag, only: [:show, :update, :destroy]

      def index
        tags = Tag.all
        tags = Tag.search(params[:q]) if params[:q].present?
        tags = tags.page(params[:page]).per(params[:per_page] || 20)

        render json: { tags: tags }, status: :ok
      end

      def show
        render json: {
          tag: @tag,
          blogs: @tag.blogs.published.recent.limit(10)
        }, status: :ok
      end

      def create
        tag = Tag.new(tag_params)

        if tag.save
          render json: { tag: tag }, status: :created
        else
          render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @tag.update(tag_params)
          render json: { tag: @tag }, status: :ok
        else
          render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @tag.destroy
        head :no_content
      end

      private

      def set_tag
        @tag = Tag.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Tag not found' }, status: :not_found
      end

      def tag_params
        params.require(:tag).permit(:name, :description)
      end
    end
  end
end
