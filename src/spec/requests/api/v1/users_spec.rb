require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  describe 'GET /api/v1/users' do
    before do
      # Clean up all users before each test
      UserStatus.delete_all
      UserProfile.delete_all
      UserCredential.delete_all
      User.delete_all
    end

    let!(:active_users) { create_list(:user, 3) }
    let!(:suspended_user) { create(:user, :suspended) }
    let!(:deleted_user) { create(:user, :deleted) }

    context 'when fetching all users' do
      it 'returns list of all users' do
        get '/api/v1/users'

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('users')
        expect(json_response['users']).to be_an(Array)
        expect(json_response['users'].length).to eq(5)
      end

      it 'returns users with full_profile structure' do
        get '/api/v1/users'

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        user = json_response['users'].first
        expect(user).to have_key('id')
        expect(user).to have_key('email')
        expect(user).to have_key('username')
        expect(user).to have_key('status')
        expect(user).to have_key('profile')
        expect(user).to have_key('created_at')
      end

      it 'does not require authentication' do
        get '/api/v1/users'

        expect(response).to have_http_status(:ok)
        expect(response).not_to have_http_status(:unauthorized)
      end
    end

    context 'when filtering by status' do
      it 'filters by active status' do
        get '/api/v1/users', params: { status: 'active' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(3)
        json_response['users'].each do |user|
          expect(user['status']).to eq('active')
        end
      end

      it 'filters by suspended status' do
        get '/api/v1/users', params: { status: 'suspended' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(1)
        expect(json_response['users'].first['status']).to eq('suspended')
      end

      it 'filters by deleted status' do
        get '/api/v1/users', params: { status: 'deleted' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(1)
        expect(json_response['users'].first['status']).to eq('deleted')
      end
    end

    context 'when using pagination' do
      before do
        # Clear existing users and create exactly 25 users
        UserStatus.delete_all
        UserProfile.delete_all
        UserCredential.delete_all
        User.delete_all
        create_list(:user, 25)
      end

      it 'supports pagination with page and per_page params' do
        get '/api/v1/users', params: { page: 1, per_page: 10 }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(10)
      end

      it 'defaults to 20 per page if per_page not specified' do
        get '/api/v1/users', params: { page: 1 }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(20)
      end
    end
  end

  describe 'GET /api/v1/users/:id' do
    let!(:user) { create(:user) }

    context 'when user exists' do
      it 'returns user full_profile' do
        get "/api/v1/users/#{user.id}"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('user')
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']['username']).to eq(user.username)
        expect(json_response['user']['status']).to eq('active')
      end

      it 'does not require authentication' do
        get "/api/v1/users/#{user.id}"

        expect(response).to have_http_status(:ok)
        expect(response).not_to have_http_status(:unauthorized)
      end
    end

    context 'when user does not exist' do
      it 'returns 404 for non-existent user' do
        get '/api/v1/users/99999'

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('User not found')
      end
    end
  end

  describe 'PATCH/PUT /api/v1/users/:id' do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let(:token) { JsonWebToken.encode(user_id: user.id) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

    context 'with authentication and authorization' do
      it 'updates user_credential email' do
        patch "/api/v1/users/#{user.id}",
              params: { user: { email: 'newemail@example.com' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['email']).to eq('newemail@example.com')
        expect(user.reload.email).to eq('newemail@example.com')
      end

      it 'updates user_profile username' do
        patch "/api/v1/users/#{user.id}",
              params: { profile: { username: 'newusername' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['username']).to eq('newusername')
        expect(user.reload.username).to eq('newusername')
      end

      it 'updates user_profile bio' do
        new_bio = 'This is my new bio'
        patch "/api/v1/users/#{user.id}",
              params: { profile: { bio: new_bio } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(user.reload.user_profile.bio).to eq(new_bio)
      end

      it 'updates user_profile avatar_url' do
        new_avatar = 'https://newavatar.com/image.jpg'
        patch "/api/v1/users/#{user.id}",
              params: { profile: { avatar_url: new_avatar } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        expect(user.reload.user_profile.avatar_url).to eq(new_avatar)
      end

      it 'updates user_profile website_url' do
        new_website = 'https://newwebsite.com'
        patch "/api/v1/users/#{user.id}",
              params: { profile: { website_url: new_website } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        expect(user.reload.user_profile.website_url).to eq(new_website)
      end

      it 'updates user_profile birth_date' do
        new_birth_date = '1990-01-01'
        patch "/api/v1/users/#{user.id}",
              params: { profile: { birth_date: new_birth_date } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        expect(user.reload.user_profile.birth_date.to_s).to eq(new_birth_date)
      end

      it 'returns updated user full_profile on success' do
        patch "/api/v1/users/#{user.id}",
              params: {
                user: { email: 'updated@example.com' },
                profile: { username: 'updatedname', bio: 'Updated bio' }
              },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('user')
        expect(json_response['user']['email']).to eq('updated@example.com')
        expect(json_response['user']['username']).to eq('updatedname')
      end
    end

    context 'without authentication' do
      it 'returns 401 without token' do
        patch "/api/v1/users/#{user.id}",
              params: { user: { email: 'newemail@example.com' } },
              as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'without authorization' do
      let(:other_token) { JsonWebToken.encode(user_id: other_user.id) }
      let(:other_auth_headers) { { 'Authorization' => "Bearer #{other_token}" } }

      it 'returns 403 when updating another user\'s profile' do
        patch "/api/v1/users/#{user.id}",
              params: { user: { email: 'newemail@example.com' } },
              headers: other_auth_headers,
              as: :json

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Forbidden')
      end
    end

    context 'with invalid data' do
      it 'returns error for invalid email format' do
        patch "/api/v1/users/#{user.id}",
              params: { user: { email: 'invalid-email' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors'].join(' ')).to match(/email/i)
      end

      it 'returns error for duplicate email' do
        patch "/api/v1/users/#{user.id}",
              params: { user: { email: other_user.email } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors'].join(' ')).to match(/email/i)
      end

      it 'returns error for invalid avatar_url format' do
        patch "/api/v1/users/#{user.id}",
              params: { profile: { avatar_url: 'not-a-valid-url' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors'].join(' ')).to match(/avatar/i)
      end

      it 'returns error for invalid website_url format' do
        patch "/api/v1/users/#{user.id}",
              params: { profile: { website_url: 'not-a-valid-url' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors'].join(' ')).to match(/website/i)
      end
    end

    context 'when user does not exist' do
      it 'returns 404 for non-existent user' do
        patch '/api/v1/users/99999',
              params: { user: { email: 'newemail@example.com' } },
              headers: auth_headers,
              as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('User not found')
      end
    end
  end

  describe 'DELETE /api/v1/users/:id' do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let(:token) { JsonWebToken.encode(user_id: user.id) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

    context 'with authentication and authorization' do
      it 'deletes user and returns 204 No Content' do
        user_id = user.id

        delete "/api/v1/users/#{user_id}", headers: auth_headers

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
        expect(User.exists?(user_id)).to be false
      end
    end

    context 'without authentication' do
      it 'returns 401 without token' do
        delete "/api/v1/users/#{user.id}"

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'without authorization' do
      let(:other_token) { JsonWebToken.encode(user_id: other_user.id) }
      let(:other_auth_headers) { { 'Authorization' => "Bearer #{other_token}" } }

      it 'returns 403 when deleting another user' do
        delete "/api/v1/users/#{user.id}", headers: other_auth_headers

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Forbidden')
      end
    end

    context 'when user does not exist' do
      it 'returns 404 for non-existent user' do
        delete '/api/v1/users/99999', headers: auth_headers

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('User not found')
      end
    end
  end
end
