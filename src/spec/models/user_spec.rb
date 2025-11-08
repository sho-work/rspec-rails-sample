require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_one(:user_credential).dependent(:destroy) }
    it { should have_one(:user_profile).dependent(:destroy) }
    it { should have_many(:user_statuses).dependent(:destroy) }
    it { should have_many(:blogs).dependent(:destroy) }
  end

  describe 'delegates' do
    let(:user) { create(:user) }

    it 'delegates email to user_credential' do
      expect(user.email).to eq(user.user_credential.email)
    end

    it 'delegates username to user_profile' do
      expect(user.username).to eq(user.user_profile.username)
    end
  end

  describe 'scopes' do
    let!(:active_user) { create(:user) }
    let!(:suspended_user) { create(:user, :suspended) }
    let!(:deleted_user) { create(:user, :deleted) }

    describe '.active_users' do
      it 'returns only active users' do
        expect(User.active_users).to include(active_user)
        expect(User.active_users).not_to include(suspended_user, deleted_user)
      end
    end

    describe '.suspended_users' do
      it 'returns only suspended users' do
        expect(User.suspended_users).to include(suspended_user)
        expect(User.suspended_users).not_to include(active_user, deleted_user)
      end
    end

    describe '.deleted_users' do
      it 'returns only deleted users' do
        expect(User.deleted_users).to include(deleted_user)
        expect(User.deleted_users).not_to include(active_user, suspended_user)
      end
    end

    describe '.with_status' do
      it 'returns users with specified status' do
        expect(User.with_status(0)).to include(active_user)
        expect(User.with_status(1)).to include(suspended_user)
        expect(User.with_status(2)).to include(deleted_user)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }

    describe '#current_status' do
      it 'returns the most recent user status' do
        expect(user.current_status).to be_a(UserStatus)
        expect(user.current_status.status).to eq('active')
      end
    end

    describe '#active?' do
      it 'returns true for active user' do
        expect(user.active?).to be true
      end

      it 'returns false for suspended user' do
        suspended_user = create(:user, :suspended)
        expect(suspended_user.active?).to be false
      end
    end

    describe '#suspended?' do
      it 'returns false for active user' do
        expect(user.suspended?).to be false
      end

      it 'returns true for suspended user' do
        suspended_user = create(:user, :suspended)
        expect(suspended_user.suspended?).to be true
      end
    end

    describe '#deleted?' do
      it 'returns false for active user' do
        expect(user.deleted?).to be false
      end

      it 'returns true for deleted user' do
        deleted_user = create(:user, :deleted)
        expect(deleted_user.deleted?).to be true
      end
    end

    describe '#change_status!' do
      it 'creates a new status record' do
        expect {
          user.change_status!(1, reason: 'Violation of terms')
        }.to change { user.user_statuses.count }.by(1)
      end

      it 'updates current status' do
        user.change_status!(1, reason: 'Violation of terms')
        expect(user.reload.current_status.status).to eq('suspended')
      end
    end

    describe '#status_history' do
      it 'returns status history ordered by effective_at' do
        user.change_status!(1, reason: 'First change')
        user.change_status!(0, reason: 'Second change')

        history = user.status_history
        expect(history.count).to eq(3) # Initial + 2 changes
        expect(history.first.reason).to eq('Second change')
      end
    end

    describe '#full_profile' do
      it 'returns a hash with user information' do
        profile = user.full_profile
        expect(profile).to be_a(Hash)
        expect(profile[:id]).to eq(user.id)
        expect(profile[:email]).to eq(user.email)
        expect(profile[:username]).to eq(user.username)
        expect(profile[:status]).to eq(0)
      end
    end

    describe '#can_login?' do
      it 'returns true for active user with unlocked account' do
        expect(user.can_login?).to be true
      end

      it 'returns false for suspended user' do
        suspended_user = create(:user, :suspended)
        expect(suspended_user.can_login?).to be false
      end

      it 'returns false for user with locked account' do
        user.user_credential.update!(locked_until: 30.minutes.from_now)
        expect(user.can_login?).to be false
      end
    end
  end

  describe 'class methods' do
    describe '.search' do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }

      before do
        user1.user_credential.update!(email: 'alice@example.com')
        user1.user_profile.update!(username: 'alice')
        user2.user_credential.update!(email: 'bob@example.com')
        user2.user_profile.update!(username: 'bob')
      end

      it 'finds users by email' do
        results = User.search('alice')
        expect(results).to include(user1)
        expect(results).not_to include(user2)
      end

      it 'finds users by username' do
        results = User.search('bob')
        expect(results).to include(user2)
        expect(results).not_to include(user1)
      end

      it 'returns empty when no match' do
        results = User.search('nonexistent')
        expect(results).to be_empty
      end
    end

    describe '.filter_by_status' do
      let!(:active_user) { create(:user) }
      let!(:suspended_user) { create(:user, :suspended) }

      it 'filters by active status' do
        results = User.filter_by_status('active')
        expect(results).to include(active_user)
        expect(results).not_to include(suspended_user)
      end

      it 'filters by suspended status' do
        results = User.filter_by_status('suspended')
        expect(results).to include(suspended_user)
        expect(results).not_to include(active_user)
      end

      it 'returns all when invalid status' do
        results = User.filter_by_status('invalid')
        expect(results).to include(active_user, suspended_user)
      end
    end
  end
end
