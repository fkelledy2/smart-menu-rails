class Ordrnote < ApplicationRecord
  belongs_to :ordr
  belongs_to :employee

  enum :category, {
    dietary: 0,
    preparation: 1,
    timing: 2,
    customer_service: 3,
    operational: 4,
  }

  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    urgent: 3,
  }

  validates :content, presence: true, length: { minimum: 3, maximum: 500 }
  validates :category, presence: true
  validates :priority, presence: true

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :for_kitchen, -> { where(visible_to_kitchen: true) }
  scope :for_servers, -> { where(visible_to_servers: true) }
  scope :for_customers, -> { where(visible_to_customers: true) }
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }
  scope :dietary_notes, -> { where(category: :dietary) }
  scope :urgent_notes, -> { where(priority: %i[high urgent]) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def high_priority?
    urgent? || high?
  end

  def editable_by?(user)
    return false unless user

    # Employee who created the note can edit within 15 minutes
    if employee.user_id == user.id
      return created_at > 15.minutes.ago
    end

    # Managers and admins can always edit
    emp = ordr.restaurant.employees.find_by(user: user)
    emp&.manager? || emp&.admin?
  end

  def category_icon
    case category
    when 'dietary' then '🚨'
    when 'preparation' then '👨‍🍳'
    when 'timing' then '⏰'
    when 'customer_service' then '💬'
    when 'operational' then '🔧'
    else '📝'
    end
  end

  def category_color
    case category
    when 'dietary' then 'danger'
    when 'preparation' then 'info'
    when 'timing' then 'warning'
    when 'customer_service' then 'success'
    when 'operational' then 'secondary'
    else 'primary'
    end
  end

  def priority_color
    case priority
    when 'urgent' then 'danger'
    when 'high' then 'warning'
    when 'medium' then 'info'
    when 'low' then 'secondary'
    else 'secondary'
    end
  end
end
