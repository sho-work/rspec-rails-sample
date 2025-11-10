require 'rails_helper'

RSpec.describe 'Api::V1::Tags', type: :request do
  describe 'GET /api/v1/tags' do
    let!(:tags) { create_list(:tag, 5) }

    context 'when fetching all tags' do
      it 'returns list of all tags' do
        get '/api/v1/tags'

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('tags')
        expect(json_response['tags']).to be_an(Array)
        expect(json_response['tags'].length).to eq(5)
      end

      it 'returns tags array in response structure' do
        get '/api/v1/tags'

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        tag = json_response['tags'].first
        expect(tag).to have_key('id')
        expect(tag).to have_key('name')
        expect(tag).to have_key('slug')
        expect(tag).to have_key('description')
      end

      it 'does not require authentication' do
        get '/api/v1/tags'

        expect(response).to have_http_status(:ok)
        expect(response).not_to have_http_status(:unauthorized)
      end
    end

    context 'when searching tags' do
      before do
        Tag.delete_all
        create(:tag, name: 'Ruby on Rails', description: 'Web framework')
        create(:tag, name: 'JavaScript', description: 'Programming language')
        create(:tag, name: 'Python', description: 'Programming language')
      end

      it 'searches tags with q parameter using Tag.search' do
        get '/api/v1/tags', params: { q: 'Ruby' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['tags'].length).to eq(1)
        expect(json_response['tags'].first['name']).to eq('Ruby on Rails')
      end

      it 'searches tags by description' do
        get '/api/v1/tags', params: { q: 'framework' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['tags'].length).to eq(1)
        expect(json_response['tags'].first['name']).to eq('Ruby on Rails')
      end
    end

    context 'when using pagination' do
      before do
        Tag.delete_all
        create_list(:tag, 25)
      end

      it 'supports pagination with page and per_page params' do
        get '/api/v1/tags', params: { page: 1, per_page: 10 }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['tags'].length).to eq(10)
      end

      it 'defaults to 20 per page if per_page not specified' do
        get '/api/v1/tags', params: { page: 1 }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['tags'].length).to eq(20)
      end
    end
  end

  describe 'GET /api/v1/tags/:id' do
    let!(:user) { create(:user) }
    let!(:tag) { create(:tag) }
    let!(:published_blogs) { create_list(:blog, 12, :published, user: user) }
    let!(:unpublished_blogs) { create_list(:blog, 3, :unpublished, user: user) }

    before do
      # Associate published blogs with tag
      published_blogs.each do |blog|
        create(:blog_tag, blog: blog, tag: tag)
      end
      # Associate unpublished blogs with tag (should not appear in response)
      unpublished_blogs.each do |blog|
        create(:blog_tag, blog: blog, tag: tag)
      end
    end

    context 'when tag exists' do
      it 'returns tag with associated published blogs' do
        get "/api/v1/tags/#{tag.id}"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('tag')
        expect(json_response).to have_key('blogs')
        expect(json_response['tag']['id']).to eq(tag.id)
        expect(json_response['tag']['name']).to eq(tag.name)
      end

      it 'response structure includes tag and blogs array' do
        get "/api/v1/tags/#{tag.id}"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('tag')
        expect(json_response).to have_key('blogs')
        expect(json_response['blogs']).to be_an(Array)
      end

      it 'returns only recent published blogs limited to 10' do
        get "/api/v1/tags/#{tag.id}"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['blogs'].length).to eq(10)
        # All returned blogs should be published
        json_response['blogs'].each do |blog|
          expect(blog['published']).to be true
        end
      end

      it 'does not require authentication' do
        get "/api/v1/tags/#{tag.id}"

        expect(response).to have_http_status(:ok)
        expect(response).not_to have_http_status(:unauthorized)
      end
    end

    context 'when tag does not exist' do
      it 'returns 404 for non-existent tag' do
        get '/api/v1/tags/99999'

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Tag not found')
      end
    end
  end

  describe 'POST /api/v1/tags' do
    let!(:user) { create(:user) }
    let(:token) { JsonWebToken.encode(user_id: user.id) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }
    let(:valid_params) do
      {
        tag: {
          name: 'New Tag',
          description: 'This is a new tag'
        }
      }
    end

    context 'with authentication' do
      it 'creates new tag with valid params' do
        expect {
          post '/api/v1/tags',
               params: valid_params,
               headers: auth_headers,
               as: :json
        }.to change(Tag, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns created tag with 201 status' do
        post '/api/v1/tags',
             params: valid_params,
             headers: auth_headers,
             as: :json

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('tag')
        expect(json_response['tag']['name']).to eq('New Tag')
        expect(json_response['tag']['description']).to eq('This is a new tag')
      end

      it 'auto-generates slug from name' do
        post '/api/v1/tags',
             params: { tag: { name: 'Ruby on Rails', description: 'Web framework' } },
             headers: auth_headers,
             as: :json

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['tag']['slug']).to eq('ruby-on-rails')
      end
    end

    context 'without authentication' do
      it 'requires authentication (401 without token)' do
        post '/api/v1/tags',
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end

    context 'with invalid params' do
      it 'failure: missing name (presence validation)' do
        post '/api/v1/tags',
             params: { tag: { description: 'No name provided' } },
             headers: auth_headers,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors'].join(' ')).to match(/name/i)
      end

      it 'failure: duplicate name (uniqueness validation)' do
        existing_tag = create(:tag, name: 'Existing Tag')

        post '/api/v1/tags',
             params: { tag: { name: 'Existing Tag', description: 'Duplicate' } },
             headers: auth_headers,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors'].join(' ')).to match(/name/i)
      end

      it 'failure: name too long (max 50 characters)' do
        long_name = 'a' * 51

        post '/api/v1/tags',
             params: { tag: { name: long_name, description: 'Too long' } },
             headers: auth_headers,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors'].join(' ')).to match(/name/i)
      end

      it 'accepts name with exactly 50 characters' do
        valid_name = 'a' * 50

        post '/api/v1/tags',
             params: { tag: { name: valid_name, description: 'Exactly 50 chars' } },
             headers: auth_headers,
             as: :json

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['tag']['name']).to eq(valid_name)
      end
    end
  end

  describe 'PATCH/PUT /api/v1/tags/:id' do
    let!(:user) { create(:user) }
    let!(:tag) { create(:tag, name: 'Original Name', description: 'Original description') }
    let(:token) { JsonWebToken.encode(user_id: user.id) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

    context 'with authentication' do
      it 'updates tag name' do
        patch "/api/v1/tags/#{tag.id}",
              params: { tag: { name: 'Updated Name' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['tag']['name']).to eq('Updated Name')
        expect(tag.reload.name).to eq('Updated Name')
      end

      it 'updates tag description' do
        patch "/api/v1/tags/#{tag.id}",
              params: { tag: { description: 'Updated description' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['tag']['description']).to eq('Updated description')
        expect(tag.reload.description).to eq('Updated description')
      end

      it 'returns updated tag with 200 status' do
        patch "/api/v1/tags/#{tag.id}",
              params: { tag: { name: 'Updated Name', description: 'Updated description' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('tag')
        expect(json_response['tag']['name']).to eq('Updated Name')
        expect(json_response['tag']['description']).to eq('Updated description')
      end
    end

    context 'without authentication' do
      it 'requires authentication (401 without token)' do
        patch "/api/v1/tags/#{tag.id}",
              params: { tag: { name: 'Updated Name' } },
              as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end

    context 'with invalid params' do
      it 'failure: invalid params (duplicate name)' do
        other_tag = create(:tag, name: 'Other Tag')

        patch "/api/v1/tags/#{tag.id}",
              params: { tag: { name: 'Other Tag' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors'].join(' ')).to match(/name/i)
      end

      it 'failure: name too long' do
        long_name = 'a' * 51

        patch "/api/v1/tags/#{tag.id}",
              params: { tag: { name: long_name } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
      end
    end

    context 'when tag does not exist' do
      it 'returns 404 for non-existent tag' do
        patch '/api/v1/tags/99999',
              params: { tag: { name: 'Updated Name' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Tag not found')
      end
    end
  end

  describe 'DELETE /api/v1/tags/:id' do
    let!(:user) { create(:user) }
    let!(:tag) { create(:tag) }
    let(:token) { JsonWebToken.encode(user_id: user.id) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

    context 'with authentication' do
      it 'deletes tag and returns 204 No Content' do
        tag_id = tag.id

        delete "/api/v1/tags/#{tag_id}", headers: auth_headers

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
        expect(Tag.exists?(tag_id)).to be false
      end
    end

    context 'without authentication' do
      it 'requires authentication (401 without token)' do
        delete "/api/v1/tags/#{tag.id}"

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
      end
    end

    context 'when tag does not exist' do
      it 'returns 404 for non-existent tag' do
        delete '/api/v1/tags/99999', headers: auth_headers

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Tag not found')
      end
    end
  end
end
