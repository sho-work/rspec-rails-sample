require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it { should have_many(:blog_tags).dependent(:destroy) }
    it { should have_many(:blogs).through(:blog_tags) }

    it 'destroys associated blog_tags when tag is destroyed' do
      tag = create(:tag)
      create_list(:blog_tag, 3, tag: tag)

      expect { tag.destroy }.to change { BlogTag.count }.by(-3)
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(1) }
    it { should validate_length_of(:name).is_at_most(50) }

    it 'validates uniqueness of name' do
      create(:tag, name: 'Ruby')
      duplicate_tag = build(:tag, name: 'Ruby')

      expect(duplicate_tag).not_to be_valid
      expect(duplicate_tag.errors[:name]).to include('has already been taken')
    end

    it 'requires slug to be present after validation' do
      tag = build(:tag, slug: nil)
      tag.valid?

      expect(tag.slug).to be_present
    end

    it 'validates uniqueness of slug' do
      create(:tag, name: 'Ruby', slug: 'ruby')
      duplicate_tag = build(:tag, name: 'Ruby Lang', slug: 'ruby')

      expect(duplicate_tag).not_to be_valid
      expect(duplicate_tag.errors[:slug]).to include('has already been taken')
    end

    it 'allows same name with different slug' do
      create(:tag, name: 'Test', slug: 'test-1')
      different_tag = build(:tag, name: 'Test Different', slug: 'test-2')

      expect(different_tag).to be_valid
    end

    it 'does not allow blank name' do
      tag = build(:tag, name: '')

      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("can't be blank")
    end
  end

  describe 'callbacks' do
    it 'generates slug before validation when slug is blank and name is present' do
      tag = build(:tag, name: 'Ruby on Rails', slug: nil)
      tag.valid?

      expect(tag.slug).to eq('ruby-on-rails')
    end

    it 'creates parameterized version of name as slug' do
      tag = create(:tag, name: 'JavaScript & TypeScript', slug: nil)

      expect(tag.slug).to eq('javascript-typescript')
    end

    it 'does not regenerate slug if already present' do
      tag = create(:tag, name: 'Ruby', slug: 'custom-slug')

      expect(tag.slug).to eq('custom-slug')
    end
  end

  describe 'scopes' do
    describe '.popular' do
      let!(:tag1) { create(:tag) }
      let!(:tag2) { create(:tag) }
      let!(:tag3) { create(:tag) }

      before do
        create_list(:blog_tag, 5, tag: tag1)
        create_list(:blog_tag, 3, tag: tag2)
        create_list(:blog_tag, 1, tag: tag3)
      end

      it 'orders tags by blog_tags count in descending order' do
        popular_tags = Tag.popular.limit(3)

        expect(popular_tags.first).to eq(tag1)
        expect(popular_tags.second).to eq(tag2)
        expect(popular_tags.third).to eq(tag3)
      end

      it 'returns tags with most blogs first' do
        popular_tags = Tag.popular

        expect(popular_tags.first.blog_tags.count).to be >= popular_tags.second.blog_tags.count
      end
    end

    describe '.recent' do
      let!(:old_tag) { create(:tag, created_at: 3.days.ago) }
      let!(:recent_tag) { create(:tag, created_at: 1.day.ago) }
      let!(:newest_tag) { create(:tag, created_at: 1.hour.ago) }

      it 'orders tags by created_at in descending order' do
        recent_tags = Tag.recent

        expect(recent_tags.first).to eq(newest_tag)
        expect(recent_tags.second).to eq(recent_tag)
        expect(recent_tags.third).to eq(old_tag)
      end

      it 'returns newest tags first' do
        recent_tags = Tag.recent

        expect(recent_tags.first.created_at).to be >= recent_tags.second.created_at
      end
    end

    describe '.by_name' do
      let!(:tag_z) { create(:tag, name: 'Zebra') }
      let!(:tag_a) { create(:tag, name: 'Apple') }
      let!(:tag_m) { create(:tag, name: 'Mango') }

      it 'orders tags by name alphabetically' do
        sorted_tags = Tag.by_name

        expect(sorted_tags.first).to eq(tag_a)
        expect(sorted_tags.second).to eq(tag_m)
        expect(sorted_tags.third).to eq(tag_z)
      end

      it 'sorts tags alphabetically by name' do
        sorted_tags = Tag.by_name.pluck(:name)

        expect(sorted_tags).to eq(sorted_tags.sort)
      end
    end
  end

  describe 'instance methods' do
    describe '#blog_count' do
      let(:tag) { create(:tag) }

      it 'returns the number of associated blogs' do
        create_list(:blog_tag, 4, tag: tag)

        expect(tag.blog_count).to eq(4)
      end

      it 'returns 0 when tag has no blogs' do
        expect(tag.blog_count).to eq(0)
      end
    end

    describe '#generate_slug' do
      it 'creates slug from name using parameterize' do
        tag = Tag.new(name: 'Ruby on Rails Programming')
        tag.generate_slug

        expect(tag.slug).to eq('ruby-on-rails-programming')
      end
    end

    describe '#related_tags' do
      let(:tag) { create(:tag) }
      let!(:related_tag1) { create(:tag) }
      let!(:related_tag2) { create(:tag) }
      let!(:related_tag3) { create(:tag) }
      let!(:unrelated_tag) { create(:tag) }

      before do
        # Create blogs for the main tag
        blog1 = create(:blog)
        blog2 = create(:blog)
        blog3 = create(:blog)

        # tag's blogs
        create(:blog_tag, blog: blog1, tag: tag)
        create(:blog_tag, blog: blog2, tag: tag)
        create(:blog_tag, blog: blog3, tag: tag)

        # related_tag1 shares 2 blogs with tag (blog1, blog2)
        create(:blog_tag, blog: blog1, tag: related_tag1)
        create(:blog_tag, blog: blog2, tag: related_tag1)

        # related_tag2 shares 2 blogs with tag (blog1, blog3)
        create(:blog_tag, blog: blog1, tag: related_tag2)
        create(:blog_tag, blog: blog3, tag: related_tag2)

        # related_tag3 shares 1 blog with tag (blog1)
        create(:blog_tag, blog: blog1, tag: related_tag3)

        # unrelated_tag doesn't share any blogs with tag
        create(:blog_tag, blog: create(:blog), tag: unrelated_tag)
      end

      it 'finds tags that share blogs with the current tag' do
        related = tag.related_tags.to_a

        expect(related).to include(related_tag1, related_tag2, related_tag3)
        expect(related).not_to include(tag, unrelated_tag)
      end

      it 'respects the limit parameter' do
        related = tag.related_tags(limit: 2).to_a

        expect(related.length).to eq(2)
      end

      it 'orders related tags by shared blog count descending' do
        related = tag.related_tags.to_a

        # related_tag1 and related_tag2 both share 2 blogs, related_tag3 shares 1
        expect([related_tag1, related_tag2]).to include(related[0])
        expect([related_tag1, related_tag2]).to include(related[1])
        expect(related[2]).to eq(related_tag3)
      end
    end
  end

  describe 'class methods' do
    describe '.search' do
      let!(:ruby_tag) { create(:tag, name: 'Ruby', description: 'A programming language') }
      let!(:rails_tag) { create(:tag, name: 'Rails', description: 'Ruby on Rails framework') }
      let!(:js_tag) { create(:tag, name: 'JavaScript', description: 'Web programming language') }

      it 'finds tags by name' do
        results = Tag.search('Ruby')

        expect(results).to include(ruby_tag)
        expect(results).not_to include(js_tag)
      end

      it 'finds tags by description' do
        results = Tag.search('framework')

        expect(results).to include(rails_tag)
        expect(results).not_to include(ruby_tag, js_tag)
      end

      it 'performs case-insensitive search' do
        results = Tag.search('ruby')

        expect(results).to include(ruby_tag, rails_tag)
      end

      it 'returns empty result when no match found' do
        results = Tag.search('nonexistent')

        expect(results).to be_empty
      end

      it 'handles partial matches' do
        results = Tag.search('prog')

        expect(results).to include(ruby_tag, js_tag)
      end
    end
  end
end
