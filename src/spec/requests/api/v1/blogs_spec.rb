require 'rails_helper'

RSpec.describe 'Api::V1::Blogs', type: :request do
  describe 'GET /api/v1/blogs' do
    let!(:blog1) { create(:blog, title: 'First Blog', published: true) }
    let!(:blog2) { create(:blog, title: 'Second Blog', published: false) }
    let!(:blog3) { create(:blog, title: 'Third Blog', published: true) }

    context 'フィルターなしの場合' do
      it '全てのブログを返すこと' do
        get '/api/v1/blogs'
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(3)
      end
    end
    
    context 'statusパラメータでフィルターする場合' do
      it 'status=publishedで公開済みブログのみを返すこと' do
        get '/api/v1/blogs', params: { status: 'published' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
        expect(json.map { |b| b['id'] }).to contain_exactly(blog1.id, blog3.id)
      end

      it 'status=unpublishedで未公開ブログのみを返すこと' do
        get '/api/v1/blogs', params: { status: 'unpublished' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first['id']).to eq(blog2.id)
      end

      it '無効なstatusの場合は全てのブログを返すこと' do
        get '/api/v1/blogs', params: { status: 'invalid' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(3)
      end
    end
  end

  describe 'GET /api/v1/blogs/:id' do
    let!(:blog) { create(:blog, title: 'Test Blog', content: 'Test Content') }

    context '存在するブログの場合' do
      it '指定されたブログを返すこと' do
        get "/api/v1/blogs/#{blog.id}"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(blog.id)
        expect(json['title']).to eq('Test Blog')
        expect(json['content']).to eq('Test Content')
      end
    end

    context '存在しないブログの場合' do
      it '404エラーを返すこと' do
        get '/api/v1/blogs/99999'
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Blog not found')
      end
    end
  end

  describe 'POST /api/v1/blogs' do
    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          blog: {
            title: 'New Blog',
            content: 'New Content',
            published: true
          }
        }
      end

      it '新しいブログを作成すること' do
        expect {
          post '/api/v1/blogs', params: valid_params
        }.to change(Blog, :count).by(1)
      end

      it '201 Createdステータスを返すこと' do
        post '/api/v1/blogs', params: valid_params
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['title']).to eq('New Blog')
        expect(json['content']).to eq('New Content')
        expect(json['published']).to eq(true)
      end
    end

    context '無効なパラメータの場合' do
      it 'titleがない場合は422エラーを返すこと' do
        invalid_params = {
          blog: {
            content: 'Content without title',
            published: true
          }
        }
        post '/api/v1/blogs', params: invalid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_an(Array)
      end

      it 'contentがない場合は422エラーを返すこと' do
        invalid_params = {
          blog: {
            title: 'Title without content',
            published: true
          }
        }
        post '/api/v1/blogs', params: invalid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/blogs/:id' do
    let!(:blog) { create(:blog, title: 'Original Title', content: 'Original Content', published: false) }

    context '有効なパラメータの場合' do
      it 'ブログを更新すること' do
        patch "/api/v1/blogs/#{blog.id}", params: {
          blog: { title: 'Updated Title' }
        }
        
        expect(response).to have_http_status(:ok)
        blog.reload
        expect(blog.title).to eq('Updated Title')
      end
    end

    context '無効なパラメータの場合' do
      it 'titleを空にした場合は422エラーを返すこと' do
        patch "/api/v1/blogs/#{blog.id}", params: {
          blog: { title: '' }
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_an(Array)
      end
    end

    context '存在しないブログの場合' do
      it '404エラーを返すこと' do
        patch '/api/v1/blogs/99999', params: {
          blog: { title: 'Updated Title' }
        }
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Blog not found')
      end
    end
  end

  describe 'DELETE /api/v1/blogs/:id' do
    let!(:blog) { create(:blog) }

    context '存在するブログの場合' do
      it 'ブログを削除すること' do
        expect {
          delete "/api/v1/blogs/#{blog.id}"
        }.to change(Blog, :count).by(-1)
      end

      it '204 No Contentステータスを返すこと' do
        delete "/api/v1/blogs/#{blog.id}"
        
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context '存在しないブログの場合' do
      it '404エラーを返すこと' do
        delete '/api/v1/blogs/99999'
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Blog not found')
      end
    end
  end
end
