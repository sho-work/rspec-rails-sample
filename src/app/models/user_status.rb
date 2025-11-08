class UserStatus < ApplicationRecord
  belongs_to :user
  belongs_to :changed_by_user, class_name: 'User', optional: true

  enum :status, { active: 0, suspended: 1, deleted: 2 }, prefix: true

  validates :user_id, presence: true
  validates :status, presence: true
  validates :effective_at, presence: true

  scope :current_status, -> {
    where(
      id: select('MAX(id) as id')
        .group(:user_id)
    )
  }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :active, -> { where(status: :active) }
  scope :suspended, -> { where(status: :suspended) }
  scope :deleted, -> { where(status: :deleted) }

  before_update :prevent_update
  before_destroy :prevent_destroy

  attr_readonly :user_id, :status, :reason, :changed_by_user_id, :effective_at, :created_at

  class << self
    def create_initial_status(user, changed_by: nil)
      create!(
        user: user,
        status: :active,
        reason: 'Initial status',
        changed_by_user: changed_by,
        effective_at: Time.current
      )
    end

    def change_status(user, new_status, reason: nil, changed_by: nil)
      create!(
        user: user,
        status: new_status,
        reason: reason,
        changed_by_user: changed_by,
        effective_at: Time.current
      )
    end
  end

  private

  def prevent_update
    raise ActiveRecord::ReadOnlyRecord, "UserStatus records are immutable and cannot be updated"
  end

  def prevent_destroy
    raise ActiveRecord::ReadOnlyRecord, "UserStatus records are immutable and cannot be destroyed"
  end
end
