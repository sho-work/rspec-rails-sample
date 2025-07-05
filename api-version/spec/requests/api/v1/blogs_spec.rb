require 'rails_helper'

RSpec.describe "Api::V1::Blogs", type: :request do
  describe "GET /api/v1/blogs" do
    let!(:blogs) { create_list(:blog, 3) }

    it "returns all blogs" do
      get api_v1_blogs_path

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
    end

    context "with search query" do
      let!(:ruby_blog) { create(:blog, title: "Ruby Tutorial", content: "Learn Ruby programming") }
      let!(:python_blog) { create(:blog, title: "Python Guide", content: "Python basics") }

      it "returns blogs matching the search query" do
        get api_v1_blogs_path, params: { q: "Ruby" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json.size).to eq(1)
        expect(json.first["title"]).to eq("Ruby Tutorial")
      end

      it "returns empty array when no matches found" do
        get api_v1_blogs_path, params: { q: "Java" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json).to be_empty
      end
    end

    context "with status filter" do
      let!(:published_blog) { create(:blog, :published) }
      let!(:unpublished_blog) { create(:blog, :unpublished) }

      it "returns only published blogs when status is published" do
        get api_v1_blogs_path, params: { status: "published" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json.size).to eq(1)
        expect(json.first["published"]).to be true
      end

      it "returns only unpublished blogs when status is unpublished" do
        get api_v1_blogs_path, params: { status: "unpublished" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        published_values = json.map { |blog| blog["published"] }
        expect(published_values).to all(be false)
      end
    end

    context "with both search query and status filter" do
      let!(:published_ruby) { create(:blog, :published, title: "Ruby Advanced", content: "Advanced Ruby") }
      let!(:unpublished_ruby) { create(:blog, :unpublished, title: "Ruby Basics", content: "Basic Ruby") }
      let!(:published_python) { create(:blog, :published, title: "Python Tutorial", content: "Learn Python") }

      it "applies both filters" do
        get api_v1_blogs_path, params: { q: "Ruby", status: "published" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json.size).to eq(1)
        expect(json.first["title"]).to eq("Ruby Advanced")
      end
    end
  end

  describe "GET /api/v1/blogs/:id" do
    let(:blog) { create(:blog) }

    context "when blog exists" do
      it "returns the blog" do
        get api_v1_blog_path(blog)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(blog.id)
        expect(json["title"]).to eq(blog.title)
      end
    end

    context "when blog does not exist" do
      it "returns not found" do
        get api_v1_blog_path(id: 999999)

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Blog not found")
      end
    end
  end

  describe "POST /api/v1/blogs" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          blog: {
            title: "New Blog Post",
            content: "This is the content",
            published: true
          }
        }
      end

      it "creates a new blog" do
        expect {
          post api_v1_blogs_path, params: valid_params
        }.to change(Blog, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["title"]).to eq("New Blog Post")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          blog: {
            title: "",
            content: "",
            published: true
          }
        }
      end

      it "returns unprocessable entity" do
        post api_v1_blogs_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "PATCH /api/v1/blogs/:id" do
    let(:blog) { create(:blog) }

    context "with valid parameters" do
      let(:valid_params) do
        {
          blog: {
            title: "Updated Title"
          }
        }
      end

      it "updates the blog" do
        patch api_v1_blog_path(blog), params: valid_params

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["title"]).to eq("Updated Title")
        expect(blog.reload.title).to eq("Updated Title")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          blog: {
            title: ""
          }
        }
      end

      it "returns unprocessable entity" do
        patch api_v1_blog_path(blog), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "DELETE /api/v1/blogs/:id" do
    let!(:blog) { create(:blog) }

    it "deletes the blog" do
      expect {
        delete api_v1_blog_path(blog)
      }.to change(Blog, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
