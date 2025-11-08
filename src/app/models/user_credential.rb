class UserCredential < ApplicationRecord
  belongs_to :user

  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }

  MAX_FAILED_ATTEMPTS = 5
  LOCK_DURATION = 30.minutes

  def authenticate_with_lock(password)
    return false if account_locked?

    if authenticate(password)
      reset_failed_attempts!
      update!(last_login_at: Time.current)
      true
    else
      increment_failed_attempts!
      false
    end
  end

  def account_locked?
    locked_until.present? && locked_until > Time.current
  end

  def lock_account!
    update!(locked_until: Time.current + LOCK_DURATION)
  end

  def unlock_account!
    update!(locked_until: nil, failed_login_attempts: 0)
  end

  def increment_failed_attempts!
    new_count = failed_login_attempts + 1
    update!(failed_login_attempts: new_count)
    lock_account! if new_count >= MAX_FAILED_ATTEMPTS
  end

  def reset_failed_attempts!
    update!(failed_login_attempts: 0, locked_until: nil)
  end

  def can_login?
    !account_locked?
  end
end
