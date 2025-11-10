require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  describe 'POST /api/v1/auth/signup' do
    let(:valid_params) do
      {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          username: 'newusername'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user with credentials, profile, and initial status' do
        expect {
          post '/api/v1/auth/signup', params: valid_params, as: :json
        }.to change(User, :count).by(1)
           .and change(UserCredential, :count).by(1)
           .and change(UserProfile, :count).by(1)
           .and change(UserStatus, :count).by(1)
      end

      it 'returns a JWT token and user profile' do
        post '/api/v1/auth/signup', params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('token')
        expect(json_response).to have_key('user')
        expect(json_response['user']['email']).to eq('newuser@example.com')
        expect(json_response['user']['username']).to eq('newusername')
        expect(json_response['user']['status']).to eq('active')
      end

      it 'creates user with active status' do
        post '/api/v1/auth/signup', params: valid_params, as: :json

        user = User.last
        expect(user.active?).to be true
        expect(user.current_status.status).to eq('active')
      end
    end

    context 'with invalid parameters' do
      it 'returns error when email is missing' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user].delete(:email)

        post '/api/v1/auth/signup', params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors'].join(' ')).to match(/email/i)
      end

      it 'returns error when password is missing' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user].delete(:password)

        post '/api/v1/auth/signup', params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors']).to be_an(Array)
      end

      it 'returns error when username is missing' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user].delete(:username)

        post '/api/v1/auth/signup', params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors']).to be_an(Array)
        expect(json_response['errors'].join(' ')).to match(/username/i)
      end

      it 'returns error when email format is invalid' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = 'invalid-email'

        post '/api/v1/auth/signup', params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors'].join(' ')).to match(/email/i)
      end

      it 'returns error when password is too short' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:password] = 'short'
        invalid_params[:user][:password_confirmation] = 'short'

        post '/api/v1/auth/signup', params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors'].join(' ')).to match(/password/i)
      end

      it 'returns error when email is already taken' do
        create(:user_credential, email: 'newuser@example.com')

        post '/api/v1/auth/signup', params: valid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors'].join(' ')).to match(/email/i)
      end
    end
  end

  describe 'POST /api/v1/auth/login' do
    let!(:user) { create(:user) }
    let(:valid_login_params) do
      {
        email: user.email,
        password: 'password123'
      }
    end

    context 'with valid credentials' do
      it 'returns JWT token and user profile' do
        post '/api/v1/auth/login', params: valid_login_params, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('token')
        expect(json_response).to have_key('user')
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']['username']).to eq(user.username)
      end

      it 'resets failed login attempts on successful login' do
        user.user_credential.update!(failed_login_attempts: 3)

        post '/api/v1/auth/login', params: valid_login_params, as: :json

        expect(response).to have_http_status(:ok)
        expect(user.user_credential.reload.failed_login_attempts).to eq(0)
      end

      it 'updates last_login_at timestamp' do
        expect {
          post '/api/v1/auth/login', params: valid_login_params, as: :json
        }.to change { user.user_credential.reload.last_login_at }
      end
    end

    context 'with invalid credentials' do
      it 'returns error when email is not found' do
        invalid_params = valid_login_params.merge(email: 'nonexistent@example.com')

        post '/api/v1/auth/login', params: invalid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'returns error when password is incorrect' do
        invalid_params = valid_login_params.merge(password: 'wrongpassword')

        post '/api/v1/auth/login', params: invalid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'increments failed_attempts on failed login' do
        invalid_params = valid_login_params.merge(password: 'wrongpassword')

        expect {
          post '/api/v1/auth/login', params: invalid_params, as: :json
        }.to change { user.user_credential.reload.failed_login_attempts }.by(1)
      end

      it 'returns error when account is locked after 5 failed attempts' do
        user.user_credential.update!(failed_login_attempts: 5, locked_until: 30.minutes.from_now)

        post '/api/v1/auth/login', params: valid_login_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Invalid credentials')
      end

      it 'locks account after reaching maximum failed attempts' do
        user.user_credential.update!(failed_login_attempts: 4)
        invalid_params = valid_login_params.merge(password: 'wrongpassword')

        post '/api/v1/auth/login', params: invalid_params, as: :json

        expect(user.user_credential.reload.account_locked?).to be true
        expect(user.user_credential.failed_login_attempts).to eq(5)
      end
    end

    context 'with suspended account' do
      let!(:suspended_user) { create(:user, :suspended) }
      let(:suspended_login_params) do
        {
          email: suspended_user.email,
          password: 'password123'
        }
      end

      it 'returns forbidden error' do
        post '/api/v1/auth/login', params: suspended_login_params, as: :json

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Account is suspended or deleted')
      end
    end

    context 'with deleted account' do
      let!(:deleted_user) { create(:user, :deleted) }
      let(:deleted_login_params) do
        {
          email: deleted_user.email,
          password: 'password123'
        }
      end

      it 'returns forbidden error' do
        post '/api/v1/auth/login', params: deleted_login_params, as: :json

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Account is suspended or deleted')
      end
    end
  end

  describe 'DELETE /api/v1/auth/logout' do
    let!(:user) { create(:user) }
    let(:token) { JsonWebToken.encode(user_id: user.id) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

    context 'with valid JWT token' do
      it 'returns 204 No Content' do
        delete '/api/v1/auth/logout', headers: auth_headers

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'without authorization header' do
      it 'returns 401 Unauthorized' do
        delete '/api/v1/auth/logout'

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'with invalid JWT token' do
      it 'returns 401 Unauthorized' do
        invalid_headers = { 'Authorization' => 'Bearer invalid_token' }

        delete '/api/v1/auth/logout', headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'GET /api/v1/auth/me' do
    let!(:user) { create(:user) }
    let(:token) { JsonWebToken.encode(user_id: user.id) }
    let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

    context 'with valid JWT token' do
      it 'returns current user full_profile' do
        get '/api/v1/auth/me', headers: auth_headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('user')
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['user']['username']).to eq(user.username)
        expect(json_response['user']['status']).to eq('active')
      end
    end

    context 'without authorization header' do
      it 'returns 401 Unauthorized' do
        get '/api/v1/auth/me'

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'with invalid JWT token' do
      it 'returns 401 Unauthorized' do
        invalid_headers = { 'Authorization' => 'Bearer invalid_token' }

        get '/api/v1/auth/me', headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'with expired JWT token' do
      it 'returns 401 Unauthorized' do
        expired_token = JsonWebToken.encode({ user_id: user.id }, 1.hour.ago)
        expired_headers = { 'Authorization' => "Bearer #{expired_token}" }

        get '/api/v1/auth/me', headers: expired_headers

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end
end
