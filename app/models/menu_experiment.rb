class MenuExperiment < ApplicationRecord
  belongs_to :menu
  belongs_to :control_version, class_name: 'MenuVersion'
  belongs_to :variant_version, class_name: 'MenuVersion'
  belongs_to :created_by_user, class_name: 'User', optional: true

  has_many :menu_experiment_exposures, dependent: :destroy

  enum :status, {
    draft: 0,
    active: 1,
    paused: 2,
    ended: 3,
  }, prefix: true

  validates :allocation_pct, presence: true,
                             numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 99 }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :ends_at_after_starts_at
  validate :starts_at_in_future, on: :create
  validate :no_overlapping_experiments
  validate :menu_has_at_least_two_versions
  validate :versions_belong_to_menu
  validate :allocation_pct_locked_when_active, on: :update

  scope :active_at, lambda { |time = Time.current|
    status_active.where('starts_at <= ? AND ends_at > ?', time, time)
  }

  def self.active_for_menu(menu, at: Time.current)
    where(menu: menu).active_at(at).first
  end

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, 'must be after starts_at') unless ends_at > starts_at
  end

  def starts_at_in_future
    return if starts_at.blank?

    errors.add(:starts_at, 'must be in the future') unless starts_at > Time.current
  end

  def no_overlapping_experiments
    return if menu_id.blank? || starts_at.blank? || ends_at.blank?

    overlap_scope = MenuExperiment
      .where(menu_id: menu_id)
      .where.not(status: %i[ended draft])
      .where('starts_at < ? AND ends_at > ?', ends_at, starts_at)

    overlap_scope = overlap_scope.where.not(id: id) if persisted?

    if overlap_scope.exists?
      errors.add(:base, 'An active or scheduled experiment already overlaps this time window for this menu')
    end
  end

  def menu_has_at_least_two_versions
    return if menu_id.blank?

    unless MenuVersion.where(menu_id: menu_id).count >= 2
      errors.add(:base, 'Menu must have at least two versions before creating an experiment')
    end
  end

  def versions_belong_to_menu
    return if menu_id.blank?

    if control_version_id.present? && MenuVersion.where(id: control_version_id, menu_id: menu_id).none?
      errors.add(:control_version, 'must belong to the selected menu')
    end

    if variant_version_id.present? && MenuVersion.where(id: variant_version_id, menu_id: menu_id).none?
      errors.add(:variant_version, 'must belong to the selected menu')
    end
  end

  def allocation_pct_locked_when_active
    return unless status_active? && allocation_pct_changed?

    errors.add(:allocation_pct, 'cannot be changed once the experiment is active')
  end
end
