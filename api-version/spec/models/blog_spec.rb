require 'rails_helper'

RSpec.describe Blog, type: :model do
  describe 'validations' do
    describe 'presence validations' do
      it 'is invalid without a title' do
        blog = build(:blog, title: nil)
        expect(blog).not_to be_valid
        expect(blog.errors[:title]).to include("can't be blank")
      end

      it 'is invalid without content' do
        blog = build(:blog, content: nil)
        expect(blog).not_to be_valid
        expect(blog.errors[:content]).to include("can't be blank")
      end

      it 'is valid with title and content' do
        blog = build(:blog)
        expect(blog).to be_valid
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:blog)).to be_valid
    end

    it 'creates unique titles with sequence' do
      blog1 = create(:blog)
      blog2 = create(:blog)
      expect(blog1.title).not_to eq(blog2.title)
    end
  end

  describe 'default values' do
    it 'sets published to false by default' do
      blog = Blog.new
      expect(blog.published).to eq(false)
    end
  end

  describe 'scopes' do
    let!(:published_blog) { create(:blog, :published) }
    let!(:unpublished_blog) { create(:blog, :unpublished) }

    describe '.published' do
      it 'returns only published blogs' do
        expect(Blog.published).to include(published_blog)
        expect(Blog.published).not_to include(unpublished_blog)
      end
    end

    describe '.unpublished' do
      it 'returns only unpublished blogs' do
        expect(Blog.unpublished).to include(unpublished_blog)
        expect(Blog.unpublished).not_to include(published_blog)
      end
    end
  end

  describe '.search' do
    let!(:blog1) { create(:blog, title: "Ruby on Rails", content: "Rails is a web framework") }
    let!(:blog2) { create(:blog, title: "JavaScript Tips", content: "Learn JavaScript easily") }
    let!(:blog3) { create(:blog, title: "Python Guide", content: "Python programming basics") }

    context 'when searching by title' do
      it 'returns blogs matching the title' do
        results = Blog.search("Ruby")
        expect(results).to include(blog1)
        expect(results).not_to include(blog2, blog3)
      end
    end

    context 'when searching by content' do
      it 'returns blogs matching the content' do
        results = Blog.search("JavaScript")
        expect(results).to include(blog2)
        expect(results).not_to include(blog1, blog3)
      end
    end

    context 'when searching with partial match' do
      it 'returns blogs with partial matches' do
        results = Blog.search("Script")
        expect(results).to include(blog2)
        expect(results).not_to include(blog1, blog3)
      end
    end

    context 'when query is blank' do
      it 'returns all blogs' do
        expect(Blog.search("")).to match_array([blog1, blog2, blog3])
        expect(Blog.search(nil)).to match_array([blog1, blog2, blog3])
      end
    end
  end

  describe '.filter_by_status' do
    let!(:published_blog) { create(:blog, :published) }
    let!(:unpublished_blog) { create(:blog, :unpublished) }

    it 'returns published blogs when status is published' do
      results = Blog.filter_by_status('published')
      expect(results).to include(published_blog)
      expect(results).not_to include(unpublished_blog)
    end

    it 'returns unpublished blogs when status is unpublished' do
      results = Blog.filter_by_status('unpublished')
      expect(results).to include(unpublished_blog)
      expect(results).not_to include(published_blog)
    end

    it 'returns all blogs when status is nil or invalid' do
      expect(Blog.filter_by_status(nil)).to match_array([published_blog, unpublished_blog])
      expect(Blog.filter_by_status('invalid')).to match_array([published_blog, unpublished_blog])
    end
  end
end
