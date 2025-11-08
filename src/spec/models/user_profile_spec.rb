require 'rails_helper'

RSpec.describe UserProfile, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }

    it 'has a valid factory' do
      user_profile = create(:user_profile)
      expect(user_profile).to be_valid
    end
  end

  describe 'validations' do
    let(:user) { create(:user) }
    subject { build(:user_profile, user: user) }

    describe 'user_id validation' do
      it { should validate_presence_of(:user_id) }
    end

    describe 'username validations' do
      it { should validate_presence_of(:username) }

      it { should validate_length_of(:username).is_at_least(1).is_at_most(50) }
    end

    describe 'bio validation' do
      it { should validate_length_of(:bio).is_at_most(500) }
    end

    describe 'avatar_url validation' do
      it 'accepts valid HTTP URL' do
        subject.avatar_url = 'http://example.com/avatar.jpg'
        subject.valid?
        expect(subject.errors[:avatar_url]).to be_empty
      end

      it 'accepts valid HTTPS URL' do
        subject.avatar_url = 'https://example.com/avatar.jpg'
        subject.valid?
        expect(subject.errors[:avatar_url]).to be_empty
      end

      it 'rejects invalid URL format' do
        subject.avatar_url = 'not-a-valid-url'
        subject.valid?
        expect(subject.errors[:avatar_url]).to include('is invalid')
      end

      it 'allows blank avatar_url' do
        subject.avatar_url = ''
        subject.valid?
        expect(subject.errors[:avatar_url]).to be_empty
      end
    end

    describe 'website_url validation' do
      it 'accepts valid HTTP URL' do
        subject.website_url = 'http://example.com'
        subject.valid?
        expect(subject.errors[:website_url]).to be_empty
      end

      it 'accepts valid HTTPS URL' do
        subject.website_url = 'https://example.com'
        subject.valid?
        expect(subject.errors[:website_url]).to be_empty
      end

      it 'rejects invalid URL format' do
        subject.website_url = 'invalid-url'
        subject.valid?
        expect(subject.errors[:website_url]).to include('is invalid')
      end

      it 'allows blank website_url' do
        subject.website_url = ''
        subject.valid?
        expect(subject.errors[:website_url]).to be_empty
      end
    end

    describe 'birth_date validation' do
      it 'accepts birth_date in the past' do
        subject.birth_date = 25.years.ago.to_date
        subject.valid?
        expect(subject.errors[:birth_date]).to be_empty
      end

      it 'rejects birth_date equal to or after today' do
        subject.birth_date = Date.today
        subject.valid?
        expect(subject.errors[:birth_date]).to include('must be less than ' + Date.today.to_s)
      end

      it 'allows blank birth_date' do
        subject.birth_date = nil
        subject.valid?
        expect(subject.errors[:birth_date]).to be_empty
      end
    end
  end

  describe 'instance methods' do
    describe '#age' do
      it 'returns nil when birth_date is nil' do
        user_profile = create(:user_profile, birth_date: nil)
        expect(user_profile.age).to be_nil
      end

      it 'calculates correct age when birthday has not occurred this year' do
        user_profile = create(:user_profile, birth_date: 25.years.ago.to_date + 1.day)
        expect(user_profile.age).to eq(24)
      end

      it 'calculates correct age when birthday has occurred this year' do
        user_profile = create(:user_profile, birth_date: 25.years.ago.to_date - 1.day)
        expect(user_profile.age).to eq(25)
      end

      it 'calculates correct age for today as birthday' do
        user_profile = create(:user_profile, birth_date: 30.years.ago.to_date)
        expect(user_profile.age).to eq(30)
      end
    end

    describe '#formatted_bio' do
      it 'returns bio when bio is present' do
        user_profile = create(:user_profile, bio: 'This is my bio')
        expect(user_profile.formatted_bio).to eq('This is my bio')
      end

      it 'returns default message when bio is nil' do
        user_profile = create(:user_profile, bio: nil)
        expect(user_profile.formatted_bio).to eq('No bio provided')
      end

      it 'returns default message when bio is empty string' do
        user_profile = create(:user_profile, bio: '')
        expect(user_profile.formatted_bio).to eq('No bio provided')
      end
    end

    describe '#display_name' do
      it 'returns username' do
        user_profile = create(:user_profile, username: 'testuser')
        expect(user_profile.display_name).to eq('testuser')
      end
    end
  end
end
