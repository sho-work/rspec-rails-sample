class Api::V1::BlogsController < ApplicationController
  before_action :set_blog, only: [:show, :update, :destroy]

  # GET /api/v1/blogs
  def index
    blogs = Blog.all
    blogs = blogs.filter_by_title(params[:title]) if params[:title].present?
    blogs = blogs.filter_by_status(params[:status]) if params[:status].present?

    render json: blogs
  end

  # GET /api/v1/blogs/:id
  def show
    render json: @blog
  end

  # POST /api/v1/blogs
  def create
    blog = Blog.new(blog_params)

    if blog.save
      render json: blog, status: :created
    else
      render json: { errors: blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/blogs/:id
  def update
    if @blog.update(blog_params)
      render json: @blog
    else
      render json: { errors: @blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/blogs/:id
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

  def blog_params
    params.require(:blog).permit(:title, :content, :published)
  end
end
