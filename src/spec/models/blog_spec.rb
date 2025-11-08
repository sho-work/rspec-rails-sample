require 'rails_helper'

RSpec.describe Blog, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:blog_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:blog_tags) }

    it 'destroys associated blog_tags when destroyed' do
      blog = create(:blog)
      tag = create(:tag)
      blog_tag = create(:blog_tag, blog: blog, tag: tag)

      expect { blog.destroy }.to change { BlogTag.count }.by(-1)
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:user_id) }
    it { should validate_numericality_of(:view_count).is_greater_than_or_equal_to(0) }
    it { should allow_value(nil).for(:view_count) }

    it 'rejects negative view_count values' do
      blog = build(:blog, view_count: -1)
      expect(blog).not_to be_valid
      expect(blog.errors[:view_count]).to include('must be greater than or equal to 0')
    end

    it 'accepts zero view_count values' do
      blog = create(:blog, view_count: 0)
      expect(blog).to be_valid
    end
  end

  describe 'scopes' do
    describe '.published' do
      let!(:published_blog) { create(:blog, published: true) }
      let!(:unpublished_blog) { create(:blog, published: false) }

      it 'returns only published blogs' do
        expect(Blog.published).to include(published_blog)
        expect(Blog.published).not_to include(unpublished_blog)
      end

      it 'filters by published status correctly' do
        expect(Blog.published.count).to eq(1)
      end
    end

    describe '.unpublished' do
      let!(:published_blog) { create(:blog, published: true) }
      let!(:unpublished_blog) { create(:blog, published: false) }

      it 'returns only unpublished blogs' do
        expect(Blog.unpublished).to include(unpublished_blog)
        expect(Blog.unpublished).not_to include(published_blog)
      end

      it 'filters by unpublished status correctly' do
        expect(Blog.unpublished.count).to eq(1)
      end
    end

    describe '.by_user' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let!(:blog1) { create(:blog, user: user1) }
      let!(:blog2) { create(:blog, user: user2) }

      it 'returns blogs for specified user' do
        expect(Blog.by_user(user1.id)).to include(blog1)
        expect(Blog.by_user(user1.id)).not_to include(blog2)
      end

      it 'filters by user_id correctly' do
        expect(Blog.by_user(user1.id).count).to eq(1)
      end
    end

    describe '.by_tag' do
      let(:tag1) { create(:tag) }
      let(:tag2) { create(:tag) }
      let!(:blog1) { create(:blog) }
      let!(:blog2) { create(:blog) }

      before do
        create(:blog_tag, blog: blog1, tag: tag1)
        create(:blog_tag, blog: blog2, tag: tag2)
      end

      it 'returns blogs with specified tag' do
        expect(Blog.by_tag(tag1.id)).to include(blog1)
        expect(Blog.by_tag(tag1.id)).not_to include(blog2)
      end

      it 'filters by tag_id correctly' do
        expect(Blog.by_tag(tag1.id).count).to eq(1)
      end
    end

    describe '.popular' do
      let!(:popular_blog) { create(:blog, published: true, view_count: 100) }
      let!(:less_popular_blog) { create(:blog, published: true, view_count: 50) }
      let!(:unpublished_blog) { create(:blog, published: false, view_count: 200) }

      it 'returns only published blogs ordered by view_count' do
        results = Blog.popular
        expect(results).to include(popular_blog, less_popular_blog)
        expect(results).not_to include(unpublished_blog)
      end

      it 'orders by view_count in descending order' do
        results = Blog.popular.to_a
        expect(results.first).to eq(popular_blog)
        expect(results.second).to eq(less_popular_blog)
      end
    end

    describe '.recent' do
      let!(:newest_blog) { create(:blog, created_at: 1.day.ago) }
      let!(:older_blog) { create(:blog, created_at: 3.days.ago) }
      let!(:oldest_blog) { create(:blog, created_at: 5.days.ago) }

      it 'returns blogs ordered by created_at' do
        results = Blog.recent.to_a
        expect(results.first).to eq(newest_blog)
        expect(results.last).to eq(oldest_blog)
      end

      it 'orders in descending order' do
        results = Blog.recent.to_a
        expect(results.map(&:id)).to eq([newest_blog.id, older_blog.id, oldest_blog.id])
      end
    end
  end

  describe 'class methods' do
    describe '.filter_by_title' do
      let!(:blog1) { create(:blog, title: 'Ruby on Rails Tutorial') }
      let!(:blog2) { create(:blog, title: 'Python Programming Guide') }
      let!(:blog3) { create(:blog, title: 'Rails Best Practices') }

      it 'filters blogs by title with LIKE' do
        results = Blog.filter_by_title('Rails')
        expect(results).to include(blog1, blog3)
        expect(results).not_to include(blog2)
      end

      it 'returns current_scope when title is blank' do
        # When called without a scope, current_scope returns nil
        # so we need to call it within a scope chain
        results = Blog.all.filter_by_title('')
        expect(results.to_a).to match_array([blog1, blog2, blog3])
      end

      it 'handles SQL injection attempts' do
        malicious_input = "'; DROP TABLE blogs; --"
        expect { Blog.filter_by_title(malicious_input) }.not_to raise_error
      end
    end

    describe '.filter_by_status' do
      let!(:published_blog) { create(:blog, published: true) }
      let!(:unpublished_blog) { create(:blog, published: false) }

      it 'filters by published status' do
        results = Blog.filter_by_status('published')
        expect(results).to include(published_blog)
        expect(results).not_to include(unpublished_blog)
      end

      it 'filters by unpublished status' do
        results = Blog.filter_by_status('unpublished')
        expect(results).to include(unpublished_blog)
        expect(results).not_to include(published_blog)
      end

      it 'returns all blogs for invalid status' do
        # When called without a scope, current_scope returns nil
        # so we need to call it within a scope chain
        results = Blog.all.filter_by_status('invalid')
        expect(results.to_a).to match_array([published_blog, unpublished_blog])
      end
    end

    describe '.search_with_tags' do
      let!(:blog1) { create(:blog, title: 'Ruby Tutorial', content: 'Learn Ruby') }
      let!(:blog2) { create(:blog, title: 'Python Guide', content: 'Learn Python') }
      let!(:tag1) { create(:tag, name: 'Ruby') }
      let!(:tag2) { create(:tag, name: 'JavaScript') }

      before do
        create(:blog_tag, blog: blog1, tag: tag1)
        create(:blog_tag, blog: blog2, tag: tag2)
      end

      it 'searches across title' do
        results = Blog.search_with_tags('Ruby')
        expect(results).to include(blog1)
      end

      it 'searches across content' do
        results = Blog.search_with_tags('Python')
        expect(results).to include(blog2)
      end

      it 'searches across tag names' do
        results = Blog.search_with_tags('JavaScript')
        expect(results).to include(blog2)
      end

      it 'returns distinct results' do
        # Blog with multiple matches should appear only once
        results = Blog.search_with_tags('Ruby')
        expect(results.count).to eq(1)
      end

      it 'handles SQL injection in search query' do
        malicious_query = "'; DROP TABLE blogs; --"
        expect { Blog.search_with_tags(malicious_query) }.not_to raise_error
      end
    end

    describe '.trending' do
      let!(:trending1) { create(:blog, published: true, view_count: 1000, created_at: 2.days.ago) }
      let!(:trending2) { create(:blog, published: true, view_count: 500, created_at: 3.days.ago) }
      let!(:old_blog) { create(:blog, published: true, view_count: 2000, created_at: 10.days.ago) }
      let!(:unpublished) { create(:blog, published: false, view_count: 1500, created_at: 1.day.ago) }

      it 'returns published blogs from last 7 days' do
        results = Blog.trending
        expect(results).to include(trending1, trending2)
        expect(results).not_to include(old_blog, unpublished)
      end

      it 'orders by view_count in descending order' do
        results = Blog.trending.to_a
        expect(results.first).to eq(trending1)
        expect(results.second).to eq(trending2)
      end

      it 'respects the limit parameter' do
        create_list(:blog, 15, published: true, created_at: 1.day.ago)
        results = Blog.trending(limit: 5)
        expect(results.count).to eq(5)
      end

      it 'uses default limit of 10' do
        create_list(:blog, 15, published: true, created_at: 1.day.ago)
        results = Blog.trending
        expect(results.count).to eq(10)
      end
    end

    describe '.filter_by_user_and_tags' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:tag1) { create(:tag) }
      let(:tag2) { create(:tag) }
      let!(:blog1) { create(:blog, user: user1) }
      let!(:blog2) { create(:blog, user: user2) }
      let!(:blog3) { create(:blog, user: user1) }

      before do
        create(:blog_tag, blog: blog1, tag: tag1)
        create(:blog_tag, blog: blog2, tag: tag2)
        create(:blog_tag, blog: blog3, tag: tag1)
      end

      it 'filters by user_id when provided' do
        results = Blog.filter_by_user_and_tags(user_id: user1.id)
        expect(results).to include(blog1, blog3)
        expect(results).not_to include(blog2)
      end

      it 'filters by tag_ids when provided' do
        results = Blog.filter_by_user_and_tags(tag_ids: [tag1.id])
        expect(results).to include(blog1, blog3)
        expect(results).not_to include(blog2)
      end

      it 'filters by both user_id and tag_ids' do
        results = Blog.filter_by_user_and_tags(user_id: user1.id, tag_ids: [tag1.id])
        expect(results).to include(blog1, blog3)
        expect(results).not_to include(blog2)
      end

      it 'returns all blogs when both are nil' do
        results = Blog.filter_by_user_and_tags(user_id: nil, tag_ids: nil)
        expect(results).to include(blog1, blog2, blog3)
      end

      it 'handles nil user_id' do
        results = Blog.filter_by_user_and_tags(user_id: nil, tag_ids: [tag1.id])
        expect(results).to include(blog1, blog3)
      end

      it 'handles nil tag_ids' do
        results = Blog.filter_by_user_and_tags(user_id: user1.id, tag_ids: nil)
        expect(results).to include(blog1, blog3)
      end
    end
  end

  describe 'instance methods' do
    describe '#increment_view!' do
      let(:blog) { create(:blog, view_count: 5) }

      it 'increments view_count by 1' do
        expect { blog.increment_view! }.to change { blog.reload.view_count }.from(5).to(6)
      end

      it 'persists the change to database' do
        blog.increment_view!
        expect(blog.reload.view_count).to eq(6)
      end
    end

    describe '#author_name' do
      it 'returns username when user has username' do
        user = create(:user)
        user.user_profile.update!(username: 'john_doe')
        blog = create(:blog, user: user)
        expect(blog.author_name).to eq('john_doe')
      end

      it 'returns "Unknown" when user is nil' do
        blog = Blog.new(user: nil)
        expect(blog.author_name).to eq('Unknown')
      end

      it 'returns username from associated user' do
        blog = create(:blog)
        expect(blog.author_name).to eq(blog.user.username)
      end
    end

    describe '#tag_list' do
      let(:blog) { create(:blog) }

      it 'returns comma-separated tag names' do
        tag1 = create(:tag, name: 'Ruby')
        tag2 = create(:tag, name: 'Rails')
        tag3 = create(:tag, name: 'Programming')
        create(:blog_tag, blog: blog, tag: tag1)
        create(:blog_tag, blog: blog, tag: tag2)
        create(:blog_tag, blog: blog, tag: tag3)

        expect(blog.tag_list).to eq('Ruby, Rails, Programming')
      end

      it 'returns empty string when blog has no tags' do
        expect(blog.tag_list).to eq('')
      end

      it 'handles single tag correctly' do
        tag = create(:tag, name: 'Ruby')
        create(:blog_tag, blog: blog, tag: tag)
        expect(blog.tag_list).to eq('Ruby')
      end
    end
  end
end
