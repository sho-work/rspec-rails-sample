class Api::V1::BlogsController < ApplicationController
  include Authenticatable
  skip_before_action :authenticate_request, only: [:index, :show]
  before_action :require_authentication!, only: [:create, :update, :destroy]
  before_action :set_blog, only: [:show, :update, :destroy]
  before_action :check_blog_ownership!, only: [:update, :destroy]

  def index
    blogs = Blog.all
    blogs = blogs.filter_by_title(params[:title]) if params[:title].present?
    blogs = blogs.filter_by_status(params[:status]) if params[:status].present?
    blogs = blogs.by_user(params[:user_id]) if params[:user_id].present?

    if params[:tag_ids].present?
      tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : [params[:tag_ids]]
      blogs = blogs.filter_by_user_and_tags(tag_ids: tag_ids)
    end

    blogs = blogs.page(params[:page]).per(params[:per_page] || 20)
    render json: blogs
  end

  def show
    @blog.increment_view!
    render json: @blog.as_json(include: { tags: { only: [:id, :name, :slug] }, user: { only: [:id], methods: [:username] } })
  end

  def create
    blog = @current_user.blogs.new(blog_params)

    if blog.save
      attach_tags(blog, params[:tag_ids]) if params[:tag_ids].present?
      render json: blog, status: :created
    else
      render json: { errors: blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @blog.update(blog_params)
      attach_tags(@blog, params[:tag_ids]) if params[:tag_ids].present?
      render json: @blog
    else
      render json: { errors: @blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @blog.destroy
    head :no_content
  end

  private

  def set_blog
    @blog = Blog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Blog not found' }, status: :not_found
  end

  def check_blog_ownership!
    unless current_user_authorized?(@blog.user)
      render json: { error: 'Forbidden' }, status: :forbidden
    end
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :published)
  end

  def attach_tags(blog, tag_ids)
    tag_ids = tag_ids.is_a?(Array) ? tag_ids : [tag_ids]
    blog.blog_tags.where.not(tag_id: tag_ids).destroy_all
    tag_ids.each do |tag_id|
      blog.blog_tags.find_or_create_by(tag_id: tag_id)
    end
  end
end
