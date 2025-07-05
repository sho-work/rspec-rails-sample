class Api::V1::BlogsController < ApplicationController
  before_action :set_blog, only: [:show, :update, :destroy]

  # GET /api/v1/blogs
  def index
    # TODO: paginationを実装する
    # TODO: class methodを利用してフィルタリングする
    # blogs = Blog.filter_by_title(params[:title])
    #             .filter_by_status(params[:status])
    blogs = Blog.all
    if params[:title].present?
      sanitized_title = sanitize_sql_for_conditions(["title LIKE ?", "%#{params[:title]}%"])
      blogs = blogs.where(sanitized_title)
    end

    if params[:status].present?
      case params[:status]
      when 'published'
        blogs = blogs.published
      when 'unpublished'
        blogs = blogs.unpublished
      end
    end

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
