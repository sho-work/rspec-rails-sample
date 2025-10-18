require 'rails_helper'

RSpec.describe Blog, type: :model do
  describe 'バリデーション' do
    it 'ファクトリが正しく動作すること' do
      blog = build(:blog)
      expect(blog).to be_valid
    end

    describe 'title' do
      it 'titleが必須であること' do
        blog = build(:blog, title: nil)
        expect(blog).not_to be_valid
        expect(blog.errors[:title]).to include("can't be blank")
      end
    end

    describe 'content' do
      it 'contentが必須であること' do
        blog = build(:blog, content: nil)
        expect(blog).not_to be_valid
        expect(blog.errors[:content]).to include("can't be blank")
      end
    end

    describe 'published' do
      it 'publishedのデフォルトがfalseであること' do
        blog = Blog.new(title: 'Test', content: 'Test content')
        expect(blog.published).to eq(false)
      end
    end
  end

  describe 'スコープ' do
    let!(:published_blog1) { create(:blog, :published) }
    let!(:published_blog2) { create(:blog, :published) }
    let!(:unpublished_blog1) { create(:blog, :unpublished) }
    let!(:unpublished_blog2) { create(:blog, :unpublished) }

    describe '.published' do
      it '公開済みのブログのみを返すこと' do
        expect(Blog.published).to contain_exactly(published_blog1, published_blog2)
      end
    end

    describe '.unpublished' do
      it '未公開のブログのみを返すこと' do
        expect(Blog.unpublished).to contain_exactly(unpublished_blog1, unpublished_blog2)
      end
    end
  end

  describe 'クラスメソッド' do
    let!(:rails_blog) { create(:blog, title: 'Ruby on Rails Tutorial') }
    let!(:react_blog) { create(:blog, title: 'React Best Practices') }
    let!(:ruby_blog) { create(:blog, title: 'Ruby Programming Guide') }

    describe '.filter_by_title' do
      context 'タイトルが指定されている場合' do
        it '部分一致するブログを返すこと' do
          result = Blog.filter_by_title('Ruby')
          expect(result).to contain_exactly(rails_blog, ruby_blog)
        end

        it '一致するブログがない場合は空の配列を返すこと' do
          result = Blog.filter_by_title('Python')
          expect(result).to be_empty
        end
      end

      context 'メソッドチェーン' do
        it 'スコープを正しく連携できること' do
          published_ruby = create(:blog, :published, title: 'Published Ruby Guide')
          create(:blog, :unpublished, title: 'Unpublished Ruby Guide')
          
          result = Blog.published.filter_by_title('Ruby')
          expect(result).to contain_exactly(published_ruby)
        end
      end
    end

    describe '.filter_by_status' do
      let!(:published_blog) { create(:blog, :published) }
      let!(:unpublished_blog) { create(:blog, :unpublished) }

      it '公開済みの記事でフィルタリングできること' do
        result = Blog.filter_by_status('published')
        expect(result).to include(published_blog)
        expect(result).not_to include(unpublished_blog)
      end

      it '未公開の記事でフィルタリングできること' do
        result = Blog.filter_by_status('unpublished')
        expect(result).to include(rails_blog, react_blog, ruby_blog, unpublished_blog)
        expect(result).not_to include(published_blog)
      end

      context 'メソッドチェーン' do
        it '未公開の記事と公開済みの記事をフィルタリングできること' do
          published_ruby = create(:blog, :published, title: 'Published Ruby Tutorial')
          create(:blog, :unpublished, title: 'Unpublished Ruby Tutorial')
          
          result = Blog.filter_by_title('Ruby').filter_by_status('published')
          expect(result).to include(published_ruby)
        end
      end
    end
  end
end
