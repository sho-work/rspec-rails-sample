require 'rails_helper'

RSpec.describe UserStatus, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:changed_by_user).class_name('User').optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:effective_at) }

    it { should define_enum_for(:status).with_values(active: 0, suspended: 1, deleted: 2).with_prefix(:status) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:status1) { user.user_statuses.first }
    let!(:status2) { create(:user_status, user: user, status: :suspended, effective_at: 1.hour.from_now) }

    describe '.current_status' do
      it 'returns the current status for each user based on max id' do
        current = UserStatus.current_status
        expect(current.pluck(:user_id)).to include(user.id)
      end
    end

    describe '.by_user' do
      let(:another_user) { create(:user) }

      it 'returns statuses for specific user' do
        results = UserStatus.by_user(user.id)
        expect(results).to include(status1, status2)
        expect(results).not_to include(another_user.user_statuses.first)
      end
    end

    describe '.active' do
      it 'returns only active statuses' do
        expect(UserStatus.active).to include(status1)
        expect(UserStatus.active).not_to include(status2)
      end
    end

    describe '.suspended' do
      it 'returns only suspended statuses' do
        expect(UserStatus.suspended).to include(status2)
        expect(UserStatus.suspended).not_to include(status1)
      end
    end

    describe '.deleted' do
      let!(:deleted_status) { create(:user_status, :deleted, user: user) }

      it 'returns only deleted statuses' do
        expect(UserStatus.deleted).to include(deleted_status)
        expect(UserStatus.deleted).not_to include(status1, status2)
      end
    end
  end

  describe 'immutability constraints' do
    let(:user_status) { create(:user_status) }

    it 'prevents update via callbacks' do
      expect {
        user_status.save!
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'prevents destroy via callbacks' do
      expect {
        user_status.destroy!
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'has readonly attributes that cannot be changed' do
      expect {
        user_status.update!(user_id: 999)
      }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe 'class methods' do
    let(:user) { create(:user) }

    describe '.create_initial_status' do
      let!(:new_user) { User.create }

      it 'creates an initial active status' do
        status = UserStatus.create_initial_status(new_user)
        expect(status).to be_persisted
        expect(status.status).to eq('active')
        expect(status.reason).to eq('Initial status')
      end

      it 'sets effective_at to current time' do
        status = UserStatus.create_initial_status(user)
        expect(status.effective_at).to be_within(2.seconds).of(Time.current)
      end
    end

    describe '.change_status' do
      it 'creates a new status record' do
        expect {
          UserStatus.change_status(user, :suspended, reason: 'Policy violation')
        }.to change { user.user_statuses.count }.by(1)
      end

      it 'sets the new status' do
        status = UserStatus.change_status(user, :suspended, reason: 'Policy violation')
        expect(status.status).to eq('suspended')
        expect(status.reason).to eq('Policy violation')
      end

      it 'tracks who changed the status' do
        admin = create(:user)
        status = UserStatus.change_status(user, :suspended, changed_by: admin)
        expect(status.changed_by_user).to eq(admin)
      end
    end
  end
end
