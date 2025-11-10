require 'rails_helper'

RSpec.describe UserCredential, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  describe 'associations' do
    it { should belong_to(:user) }

    it 'has a valid factory' do
      user_credential = create(:user_credential)
      expect(user_credential).to be_valid
    end
  end

  describe 'validations' do
    let(:user) { create(:user) }
    subject { build(:user_credential, user: user) }

    describe 'email validations' do
      it { should validate_presence_of(:email) }

      it 'validates uniqueness of email' do
        user1 = create(:user)
        existing_email = user1.user_credential.email
        duplicate = build(:user_credential, email: existing_email)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:email]).to include('has already been taken')
      end

      it 'accepts valid email format' do
        subject.email = 'valid.email@example.com'
        subject.valid?
        expect(subject.errors[:email]).to be_empty
      end

      it 'rejects invalid email format without @' do
        subject.email = 'invalidemail.com'
        subject.valid?
        expect(subject.errors[:email]).to include('is invalid')
      end

      it 'rejects invalid email format without domain' do
        subject.email = 'invalid@'
        subject.valid?
        expect(subject.errors[:email]).to include('is invalid')
      end
    end

    describe 'password validations' do
      it 'validates minimum length of password' do
        subject.password = 'short'
        subject.password_confirmation = 'short'
        subject.valid?
        expect(subject.errors[:password]).to include('is too short (minimum is 6 characters)')
      end

      it 'accepts password with exactly 6 characters' do
        subject.password = '123456'
        subject.password_confirmation = '123456'
        subject.valid?
        expect(subject.errors[:password]).to be_empty
      end

      it 'accepts password with more than 6 characters' do
        subject.password = 'validpassword123'
        subject.password_confirmation = 'validpassword123'
        subject.valid?
        expect(subject.errors[:password]).to be_empty
      end
    end

    # user_id validation is handled automatically by belongs_to association
    # No explicit validation needed in the model
  end

  describe 'authentication logic' do
    let(:user_credential) { create(:user_credential, password: 'password123', password_confirmation: 'password123') }

    describe '#authenticate_with_lock' do
      context 'when account is not locked' do
        it 'returns true for correct password' do
          expect(user_credential.authenticate_with_lock('password123')).to be true
        end

        it 'returns false for incorrect password' do
          expect(user_credential.authenticate_with_lock('wrongpassword')).to be false
        end

        it 'updates last_login_at on successful authentication' do
          travel_to Time.current do
            expect {
              user_credential.authenticate_with_lock('password123')
            }.to change { user_credential.reload.last_login_at }.to(Time.current)
          end
        end

        it 'resets failed_login_attempts on successful authentication' do
          user_credential.update!(failed_login_attempts: 3)
          user_credential.authenticate_with_lock('password123')
          expect(user_credential.reload.failed_login_attempts).to eq(0)
        end

        it 'increments failed_login_attempts on failed authentication' do
          expect {
            user_credential.authenticate_with_lock('wrongpassword')
          }.to change { user_credential.reload.failed_login_attempts }.by(1)
        end

        it 'does not update last_login_at on failed authentication' do
          expect {
            user_credential.authenticate_with_lock('wrongpassword')
          }.not_to change { user_credential.reload.last_login_at }
        end
      end

      context 'when account is locked' do
        before do
          user_credential.lock_account!
        end

        it 'returns false even with correct password' do
          expect(user_credential.authenticate_with_lock('password123')).to be false
        end

        it 'does not increment failed_login_attempts' do
          expect {
            user_credential.authenticate_with_lock('password123')
          }.not_to change { user_credential.reload.failed_login_attempts }
        end

        it 'does not update last_login_at' do
          expect {
            user_credential.authenticate_with_lock('password123')
          }.not_to change { user_credential.reload.last_login_at }
        end
      end
    end
  end

  describe 'account lock functionality' do
    let(:user_credential) { create(:user_credential) }

    describe '#account_locked?' do
      it 'returns false when locked_until is nil' do
        user_credential.update!(locked_until: nil)
        expect(user_credential.account_locked?).to be false
      end

      it 'returns true when locked_until is in the future' do
        user_credential.update!(locked_until: 10.minutes.from_now)
        expect(user_credential.account_locked?).to be true
      end

      it 'returns false when locked_until is in the past' do
        user_credential.update!(locked_until: 10.minutes.ago)
        expect(user_credential.account_locked?).to be false
      end
    end

    describe '#lock_account!' do
      it 'sets locked_until to 30 minutes from now' do
        travel_to Time.current do
          user_credential.lock_account!
          expect(user_credential.reload.locked_until).to be_within(1.second).of(30.minutes.from_now)
        end
      end

      it 'makes account_locked? return true' do
        user_credential.lock_account!
        expect(user_credential.reload.account_locked?).to be true
      end
    end

    describe '#unlock_account!' do
      before do
        user_credential.update!(locked_until: 30.minutes.from_now, failed_login_attempts: 5)
      end

      it 'sets locked_until to nil' do
        user_credential.unlock_account!
        expect(user_credential.reload.locked_until).to be_nil
      end

      it 'resets failed_login_attempts to 0' do
        user_credential.unlock_account!
        expect(user_credential.reload.failed_login_attempts).to eq(0)
      end
    end

    describe '#increment_failed_attempts!' do
      it 'increments failed_login_attempts by 1' do
        expect {
          user_credential.increment_failed_attempts!
        }.to change { user_credential.reload.failed_login_attempts }.by(1)
      end

      it 'locks account when reaching MAX_FAILED_ATTEMPTS' do
        user_credential.update!(failed_login_attempts: 4)
        user_credential.increment_failed_attempts!
        expect(user_credential.reload.account_locked?).to be true
      end

      it 'does not lock account before reaching MAX_FAILED_ATTEMPTS' do
        user_credential.update!(failed_login_attempts: 3)
        user_credential.increment_failed_attempts!
        expect(user_credential.reload.account_locked?).to be false
      end
    end

    describe '#reset_failed_attempts!' do
      before do
        user_credential.update!(failed_login_attempts: 3, locked_until: 30.minutes.from_now)
      end

      it 'resets failed_login_attempts to 0' do
        user_credential.reset_failed_attempts!
        expect(user_credential.reload.failed_login_attempts).to eq(0)
      end

      it 'sets locked_until to nil' do
        user_credential.reset_failed_attempts!
        expect(user_credential.reload.locked_until).to be_nil
      end
    end

    describe '#can_login?' do
      it 'returns true when account is not locked' do
        expect(user_credential.can_login?).to be true
      end

      it 'returns false when account is locked' do
        user_credential.lock_account!
        expect(user_credential.reload.can_login?).to be false
      end
    end
  end
end
