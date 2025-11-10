class User < ApplicationRecord
  has_one :user_credential, dependent: :destroy
  has_one :user_profile, dependent: :destroy
  has_many :user_statuses, dependent: :delete_all
  has_many :blogs, dependent: :destroy

  validates_associated :user_credential, :user_profile

  delegate :email, to: :user_credential, allow_nil: true
  delegate :username, to: :user_profile, allow_nil: true

  scope :active_users, -> { joins(:user_statuses).merge(UserStatus.current_status.where(status: 0)) }
  scope :suspended_users, -> { joins(:user_statuses).merge(UserStatus.current_status.where(status: 1)) }
  scope :deleted_users, -> { joins(:user_statuses).merge(UserStatus.current_status.where(status: 2)) }
  scope :with_status, ->(status) { joins(:user_statuses).merge(UserStatus.current_status.where(status: status)) }

  def current_status
    user_statuses.order(effective_at: :desc).first
  end

  def active?
    current_status&.status_active?
  end

  def suspended?
    current_status&.status_suspended?
  end

  def deleted?
    current_status&.status_deleted?
  end

  def change_status!(new_status, reason: nil, changed_by: nil)
    user_statuses.create!(
      status: new_status,
      reason: reason,
      changed_by_user: changed_by,
      effective_at: Time.current
    )
  end

  def status_history
    user_statuses.order(effective_at: :desc)
  end

  def full_profile
    {
      id: id,
      email: email,
      username: username,
      status: current_status&.status,
      profile: user_profile,
      created_at: created_at
    }
  end

  def can_login?
    active? && user_credential&.can_login?
  end

  class << self
    def search(query)
      joins(:user_credential, :user_profile)
        .where(
          "user_credentials.email LIKE ? OR user_profiles.username LIKE ?",
          "%#{sanitize_sql_like(query)}%",
          "%#{sanitize_sql_like(query)}%"
        )
        .distinct
    end

    def filter_by_status(status)
      case status
      when 'active'
        active_users
      when 'suspended'
        suspended_users
      when 'deleted'
        deleted_users
      else
        all
      end
    end
  end
end
