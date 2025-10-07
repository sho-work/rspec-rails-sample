# frozen_string_literal: true

RSpec.describe 'Api::V1::BlogsController', type: :request do
  describe 'GET /api/v1/blogs' do
    context 'ブログが存在する場合' do
      let!(:blogs) { create_list(:blog, 3) }

      it '全てのブログが取得できることを確認する' do
        aggregate_failures do
          get '/api/v1/blogs'
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.length).to eq(3)
        end
      end
    end


    context 'ステータスでフィルタリングする場合' do
      let!(:published_blogs) { create_list(:blog, 2, :published) }
      let!(:unpublished_blogs) { create_list(:blog, 3, :unpublished) }

      it '公開済みのブログのみ取得できることを確認する' do
        aggregate_failures do
          get '/api/v1/blogs', params: { status: 'published' }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.length).to eq(2)
          expect(response.parsed_body.all? { _1['published'] }).to be true
        end
      end

      it '未公開のブログのみ取得できることを確認する' do
        aggregate_failures do
          get '/api/v1/blogs', params: { status: 'unpublished' }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.length).to eq(3)
          expect(response.parsed_body.all? { !_1['published'] }).to be true
        end
      end
    end
  end

  describe 'GET /api/v1/blogs/:id' do
    context 'ブログが存在する場合' do
      let!(:blog) { create(:blog) }

      it '指定したブログが取得できることを確認する' do
        aggregate_failures do
          get "/api/v1/blogs/#{blog.id}"
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body['id']).to eq(blog.id)
          expect(response.parsed_body['title']).to eq(blog.title)
          expect(response.parsed_body['content']).to eq(blog.content)
        end
      end
    end

    context '存在しないブログを取得しようとした場合' do
      it '404が返ることを確認する' do
        aggregate_failures do
          get '/api/v1/blogs/0'
          expect(response).to have_http_status(:not_found)
          expect(response.parsed_body['error']).to eq('Blog not found')
        end
      end
    end
  end

  describe 'POST /api/v1/blogs' do
    context 'タイトルとコンテンツが有効な場合' do
      let(:valid_blog_params) do
        { title: 'New Blog', content: 'This is a new blog content', published: true }
      end

      it 'blogレコードが追加され、201になる' do
        aggregate_failures do
          expect { post '/api/v1/blogs', params: { blog: valid_blog_params }, as: :json }.to change(Blog, :count).by(+1)
          expect(response).to have_http_status(:created)
          expect(response.parsed_body['title']).to eq('New Blog')
          expect(response.parsed_body['content']).to eq('This is a new blog content')
          expect(response.parsed_body['published']).to be true
        end
      end
    end

    context 'バリデーションエラーになる場合' do
      let(:invalid_blog_params) { { title: '', content: '' } }

      it '422になり、エラーメッセージがレスポンスとして返る' do
        aggregate_failures do
          post '/api/v1/blogs', params: { blog: invalid_blog_params }, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['errors']).to include('Title can\'t be blank', 'Content can\'t be blank')
        end
      end
    end
  end

  describe 'PUT /api/v1/blogs/:id' do
    context 'コンテンツが有効な場合' do
      let(:existing_blog) { create(:blog) }
      let(:params) { { content: '新しいコンテンツ', published: true } }

      it 'blogが更新され、200になる' do
        aggregate_failures do
          put "/api/v1/blogs/#{existing_blog.id}", params: { blog: params }, as: :json
          expect(response).to have_http_status(:ok)
          existing_blog.reload
          expect(existing_blog.content).to eq('新しいコンテンツ')
          expect(existing_blog.published).to be true
        end
      end
    end

    context 'バリデーションエラーになる場合' do
      let(:existing_blog) { create(:blog) }
      let(:params) { { content: '' } }

      it '422になり、エラーメッセージがレスポンスとして返る' do
        aggregate_failures do
          put "/api/v1/blogs/#{existing_blog.id}", params: { blog: params }, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['errors']).to include('Content can\'t be blank')
        end
      end
    end

    context '存在しないブログを更新しようとした場合' do
      let(:params) { { content: '新しいコンテンツ' } }

      it '404が返ることを確認する' do
        aggregate_failures do
          put '/api/v1/blogs/0', params: { blog: params }, as: :json
          expect(response).to have_http_status(:not_found)
          expect(response.parsed_body['error']).to eq('Blog not found')
        end
      end
    end
  end

  describe 'DELETE /api/v1/blogs/:id' do
    context 'ブログを削除しようとした場合' do
      let!(:existing_blog) { create(:blog) }

      it 'ブログが削除されたことを確認する' do
        aggregate_failures do
          expect { delete "/api/v1/blogs/#{existing_blog.id}" }.to change(Blog, :count).by(-1)
          expect(response).to have_http_status(:no_content)
        end
      end
    end

    context '存在しないブログを削除しようとした場合' do
      it '404が返ることを確認する' do
        aggregate_failures do
          expect { delete '/api/v1/blogs/0' }.not_to change(Blog, :count)
          expect(response).to have_http_status(:not_found)
          expect(response.parsed_body['error']).to eq('Blog not found')
        end
      end
    end
  end
end
