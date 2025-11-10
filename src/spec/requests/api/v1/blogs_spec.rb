require 'rails_helper'

RSpec.describe 'Api::V1::Blogs', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/blogs' do
    context 'when retrieving all blogs' do
      let!(:blogs) { create_list(:blog, 5, user: user) }

      it 'returns list of all blogs' do
        get '/api/v1/blogs'

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(5)
      end

      it 'does not require authentication' do
        get '/api/v1/blogs'

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when filtering by title' do
      let!(:blog1) { create(:blog, title: 'Ruby on Rails Guide', user: user) }
      let!(:blog2) { create(:blog, title: 'Python Tutorial', user: user) }
      let!(:blog3) { create(:blog, title: 'Advanced Rails', user: user) }

      it 'filters blogs by title parameter using partial match' do
        get '/api/v1/blogs', params: { title: 'Rails' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(2)
        titles = json_response.map { |b| b['title'] }
        expect(titles).to include('Ruby on Rails Guide', 'Advanced Rails')
        expect(titles).not_to include('Python Tutorial')
      end
    end

    context 'when filtering by status' do
      let!(:published_blogs) { create_list(:blog, 3, :published, user: user) }
      let!(:unpublished_blogs) { create_list(:blog, 2, :unpublished, user: user) }

      it 'filters blogs by published status' do
        get '/api/v1/blogs', params: { status: 'published' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(3)
        expect(json_response.all? { |b| b['published'] == true }).to be true
      end

      it 'filters blogs by unpublished status' do
        get '/api/v1/blogs', params: { status: 'unpublished' }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(2)
        expect(json_response.all? { |b| b['published'] == false }).to be true
      end
    end

    context 'when filtering by user_id' do
      let!(:user_blogs) { create_list(:blog, 3, user: user) }
      let!(:other_user_blogs) { create_list(:blog, 2, user: other_user) }

      it 'filters blogs by user_id parameter' do
        get '/api/v1/blogs', params: { user_id: user.id }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(3)
        expect(json_response.all? { |b| b['user_id'] == user.id }).to be true
      end
    end

    context 'when filtering by tag_ids' do
      let!(:tag1) { create(:tag) }
      let!(:tag2) { create(:tag) }
      let!(:tag3) { create(:tag) }
      let!(:blog1) { create(:blog, user: user) }
      let!(:blog2) { create(:blog, user: user) }
      let!(:blog3) { create(:blog, user: user) }

      before do
        create(:blog_tag, blog: blog1, tag: tag1)
        create(:blog_tag, blog: blog2, tag: tag2)
        create(:blog_tag, blog: blog3, tag: tag3)
      end

      it 'filters blogs by single tag_id' do
        get '/api/v1/blogs', params: { tag_ids: tag1.id }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(blog1.id)
      end

      it 'filters blogs by array of tag_ids' do
        get '/api/v1/blogs', params: { tag_ids: [tag1.id, tag2.id] }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(2)
        blog_ids = json_response.map { |b| b['id'] }
        expect(blog_ids).to include(blog1.id, blog2.id)
      end
    end

    context 'when using pagination' do
      let!(:blogs) { create_list(:blog, 25, user: user) }

      it 'supports pagination with page and per_page params' do
        get '/api/v1/blogs', params: { page: 2, per_page: 10 }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(10)
      end

      it 'defaults to 20 per page if per_page not specified' do
        get '/api/v1/blogs', params: { page: 1 }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(20)
      end

      it 'returns remaining items on last page' do
        get '/api/v1/blogs', params: { page: 2 }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(5)
      end
    end
  end

  describe 'GET /api/v1/blogs/:id' do
    let!(:tag1) { create(:tag) }
    let!(:tag2) { create(:tag) }
    let!(:blog) { create(:blog, user: user) }

    before do
      create(:blog_tag, blog: blog, tag: tag1)
      create(:blog_tag, blog: blog, tag: tag2)
    end

    context 'when blog exists' do
      it 'returns blog with associated tags and user info' do
        get "/api/v1/blogs/#{blog.id}"
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(blog.id)
        expect(json_response['title']).to eq(blog.title)
        expect(json_response['content']).to eq(blog.content)
      end

      it 'response includes tags with id, name, slug' do
        get "/api/v1/blogs/#{blog.id}"
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('tags')
        expect(json_response['tags']).to be_an(Array)
        expect(json_response['tags'].size).to eq(2)

        tag = json_response['tags'].first
        expect(tag.keys).to match_array(['id', 'name', 'slug'])
        expect(tag['id']).to be_present
        expect(tag['name']).to be_present
        expect(tag['slug']).to be_present
      end

      it 'response includes user with id and username' do
        get "/api/v1/blogs/#{blog.id}"
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('user')
        expect(json_response['user']).to be_a(Hash)
        expect(json_response['user']).to have_key('id')
        expect(json_response['user']).to have_key('username')
        expect(json_response['user']['id']).to eq(user.id)
      end

      it 'increments view_count' do
        expect {
          get "/api/v1/blogs/#{blog.id}"        }.to change { blog.reload.view_count }.by(1)
      end

      it 'does not require authentication' do
        get "/api/v1/blogs/#{blog.id}"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when blog does not exist' do
      it 'returns 404 for non-existent blog' do
        get '/api/v1/blogs/99999'
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Blog not found')
      end
    end
  end

  describe 'POST /api/v1/blogs' do
    let(:valid_params) do
      {
        blog: {
          title: 'New Blog Post',
          content: 'This is the content of the blog post',
          published: true
        }
      }
    end

    context 'with authentication' do
      context 'with valid params' do
        it 'creates new blog with valid params' do
          expect {
            post '/api/v1/blogs', params: valid_params, headers: auth_headers, as: :json
          }.to change(Blog, :count).by(1)

          expect(response).to have_http_status(:created)
        end

        it 'returns created blog with 201 status' do
          post '/api/v1/blogs', params: valid_params, headers: auth_headers, as: :json

          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response['title']).to eq('New Blog Post')
          expect(json_response['content']).to eq('This is the content of the blog post')
          expect(json_response['published']).to eq(true)
        end

        it 'associates blog with current_user' do
          post '/api/v1/blogs', params: valid_params, headers: auth_headers, as: :json

          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response['user_id']).to eq(user.id)
          expect(Blog.last.user_id).to eq(user.id)
        end

        it 'attaches tags using tag_ids parameter' do
          tag1 = create(:tag)
          tag2 = create(:tag)
          params_with_tags = valid_params.merge(tag_ids: [tag1.id, tag2.id])

          post '/api/v1/blogs', params: params_with_tags, headers: auth_headers, as: :json

          expect(response).to have_http_status(:created)
          created_blog = Blog.last
          expect(created_blog.tags.pluck(:id)).to match_array([tag1.id, tag2.id])
        end
      end

      context 'with invalid params' do
        it 'returns error when title is missing' do
          invalid_params = valid_params.deep_dup
          invalid_params[:blog].delete(:title)

          post '/api/v1/blogs', params: invalid_params, headers: auth_headers, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('errors')
          expect(json_response['errors']).to be_an(Array)
          expect(json_response['errors'].join(' ')).to match(/title/i)
        end

        it 'returns error when content is missing' do
          invalid_params = valid_params.deep_dup
          invalid_params[:blog].delete(:content)

          post '/api/v1/blogs', params: invalid_params, headers: auth_headers, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('errors')
          expect(json_response['errors']).to be_an(Array)
          expect(json_response['errors'].join(' ')).to match(/content/i)
        end
      end
    end

    context 'without authentication' do
      it 'returns 401 without token' do
        post '/api/v1/blogs', params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'PATCH /api/v1/blogs/:id' do
    let!(:blog) { create(:blog, title: 'Original Title', content: 'Original Content', published: false, user: user) }

    context 'with authentication and ownership' do
      context 'with valid params' do
        it 'updates blog title' do
          patch "/api/v1/blogs/#{blog.id}",
                params: { blog: { title: 'Updated Title' } },
                headers: auth_headers,
                as: :json

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['title']).to eq('Updated Title')
          expect(blog.reload.title).to eq('Updated Title')
        end

        it 'updates blog content' do
          patch "/api/v1/blogs/#{blog.id}",
                params: { blog: { content: 'Updated Content' } },
                headers: auth_headers,
                as: :json

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['content']).to eq('Updated Content')
          expect(blog.reload.content).to eq('Updated Content')
        end

        it 'updates blog published status' do
          patch "/api/v1/blogs/#{blog.id}",
                params: { blog: { published: true } },
                headers: auth_headers,
                as: :json

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['published']).to eq(true)
          expect(blog.reload.published).to eq(true)
        end

        it 'updates blog tags using tag_ids parameter' do
          tag1 = create(:tag)
          tag2 = create(:tag)
          tag3 = create(:tag)

          create(:blog_tag, blog: blog, tag: tag1)

          patch "/api/v1/blogs/#{blog.id}",
                params: { blog: { title: blog.title }, tag_ids: [tag2.id, tag3.id] },
                headers: auth_headers,
                as: :json

          expect(response).to have_http_status(:ok)
          expect(blog.reload.tags.pluck(:id)).to match_array([tag2.id, tag3.id])
        end

        it 'returns updated blog with 200 status' do
          patch "/api/v1/blogs/#{blog.id}",
                params: { blog: { title: 'Updated Title' } },
                headers: auth_headers,
                as: :json

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['id']).to eq(blog.id)
          expect(json_response['title']).to eq('Updated Title')
        end
      end

      context 'with invalid params' do
        it 'returns error when title is blank' do
          patch "/api/v1/blogs/#{blog.id}",
                params: { blog: { title: '' } },
                headers: auth_headers,
                as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key('errors')
          expect(json_response['errors']).to be_an(Array)
        end
      end
    end

    context 'without authentication' do
      it 'returns 401 without token' do
        patch "/api/v1/blogs/#{blog.id}",
              params: { blog: { title: 'Updated Title' } },
              headers: { 'Content-Type' => 'application/json' },
              as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'without ownership' do
      let(:other_user_token) { JsonWebToken.encode(user_id: other_user.id) }
      let(:other_user_headers) { { 'Authorization' => "Bearer #{other_user_token}" } }

      it 'returns 403 when updating another users blog' do
        patch "/api/v1/blogs/#{blog.id}",
              params: { blog: { title: 'Hacked Title' } },
              headers: other_user_headers,
              as: :json

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Forbidden')
        expect(blog.reload.title).to eq('Original Title')
      end
    end

    context 'when blog does not exist' do
      it 'returns 404 for non-existent blog' do
        patch '/api/v1/blogs/99999',
              params: { blog: { title: 'Updated Title' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Blog not found')
      end
    end
  end

  describe 'DELETE /api/v1/blogs/:id' do
    let!(:blog) { create(:blog, user: user) }

    context 'with authentication and ownership' do
      it 'deletes blog and returns 204 No Content' do
        expect {
          delete "/api/v1/blogs/#{blog.id}", headers: auth_headers
        }.to change(Blog, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'without authentication' do
      it 'returns 401 without token' do
        delete "/api/v1/blogs/#{blog.id}"
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'without ownership' do
      let(:other_user_token) { JsonWebToken.encode(user_id: other_user.id) }
      let(:other_user_headers) { { 'Authorization' => "Bearer #{other_user_token}" } }

      it 'returns 403 when deleting another users blog' do
        expect {
          delete "/api/v1/blogs/#{blog.id}", headers: other_user_headers
        }.not_to change(Blog, :count)

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Forbidden')
      end
    end

    context 'when blog does not exist' do
      it 'returns 404 for non-existent blog' do
        delete '/api/v1/blogs/99999', headers: auth_headers

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Blog not found')
      end
    end
  end
end
