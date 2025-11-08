require 'rails_helper'

RSpec.describe BlogTag, type: :model do
  describe 'associations' do
    it { should belong_to(:blog) }
    it { should belong_to(:tag) }
  end

  describe 'validations' do
    describe 'blog_id' do
      it { should validate_presence_of(:blog_id) }
    end

    describe 'tag_id' do
      it { should validate_presence_of(:tag_id) }
    end

    describe 'uniqueness' do
      let(:blog) { create(:blog) }
      let(:tag) { create(:tag) }

      before do
        create(:blog_tag, blog: blog, tag: tag)
      end

      it 'validates uniqueness of blog_id scoped to tag_id' do
        duplicate = build(:blog_tag, blog: blog, tag: tag)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:blog_id]).to include('has already been taken')
      end

      it 'allows same blog with different tags' do
        different_tag = create(:tag)
        blog_tag = build(:blog_tag, blog: blog, tag: different_tag)

        expect(blog_tag).to be_valid
      end

      it 'allows same tag with different blogs' do
        different_blog = create(:blog)
        blog_tag = build(:blog_tag, blog: different_blog, tag: tag)

        expect(blog_tag).to be_valid
      end
    end
  end

  describe 'scopes' do
    describe '.by_blog' do
      let(:blog1) { create(:blog) }
      let(:blog2) { create(:blog) }
      let(:tag1) { create(:tag) }
      let(:tag2) { create(:tag) }

      let!(:blog1_tag1) { create(:blog_tag, blog: blog1, tag: tag1) }
      let!(:blog1_tag2) { create(:blog_tag, blog: blog1, tag: tag2) }
      let!(:blog2_tag1) { create(:blog_tag, blog: blog2, tag: tag1) }

      it 'filters blog_tags by blog_id' do
        results = BlogTag.by_blog(blog1.id)

        expect(results).to include(blog1_tag1, blog1_tag2)
        expect(results).not_to include(blog2_tag1)
      end

      it 'returns only blog_tags for the specified blog' do
        results = BlogTag.by_blog(blog1.id)

        expect(results.count).to eq(2)
        expect(results.pluck(:blog_id).uniq).to eq([blog1.id])
      end

      it 'returns empty result when no blog_tags exist for the blog' do
        non_existent_blog = create(:blog)
        results = BlogTag.by_blog(non_existent_blog.id)

        expect(results).to be_empty
      end
    end

    describe '.by_tag' do
      let(:blog1) { create(:blog) }
      let(:blog2) { create(:blog) }
      let(:tag1) { create(:tag) }
      let(:tag2) { create(:tag) }

      let!(:blog1_tag1) { create(:blog_tag, blog: blog1, tag: tag1) }
      let!(:blog2_tag1) { create(:blog_tag, blog: blog2, tag: tag1) }
      let!(:blog1_tag2) { create(:blog_tag, blog: blog1, tag: tag2) }

      it 'filters blog_tags by tag_id' do
        results = BlogTag.by_tag(tag1.id)

        expect(results).to include(blog1_tag1, blog2_tag1)
        expect(results).not_to include(blog1_tag2)
      end

      it 'returns only blog_tags for the specified tag' do
        results = BlogTag.by_tag(tag1.id)

        expect(results.count).to eq(2)
        expect(results.pluck(:tag_id).uniq).to eq([tag1.id])
      end

      it 'returns empty result when no blog_tags exist for the tag' do
        non_existent_tag = create(:tag)
        results = BlogTag.by_tag(non_existent_tag.id)

        expect(results).to be_empty
      end

      it 'can be chained with by_blog scope' do
        results = BlogTag.by_blog(blog1.id).by_tag(tag1.id)

        expect(results).to include(blog1_tag1)
        expect(results).not_to include(blog2_tag1, blog1_tag2)
        expect(results.count).to eq(1)
      end
    end

    describe 'scope chaining' do
      let(:blog) { create(:blog) }
      let(:tag) { create(:tag) }
      let!(:blog_tag) { create(:blog_tag, blog: blog, tag: tag) }

      it 'allows combining by_blog and by_tag to find specific associations' do
        results = BlogTag.by_blog(blog.id).by_tag(tag.id)

        expect(results).to contain_exactly(blog_tag)
      end
    end
  end
end
