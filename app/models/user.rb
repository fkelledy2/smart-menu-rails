class User < ApplicationRecord
  include IdentityCache

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: %i[google_oauth2 apple]

  has_one_attached :avatar
  has_person_name

  has_many :notifications, as: :recipient, dependent: :destroy, class_name: 'Noticed::Notification'
  has_many :notification_mentions, as: :record, dependent: :destroy, class_name: 'Noticed::Event'
  has_many :services
  has_many :userplans, dependent: :destroy
  has_many :testimonials, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy

  belongs_to :plan, optional: true
  has_many :restaurants, dependent: :destroy
  has_one :onboarding_session, dependent: :destroy

  # IdentityCache configuration
  cache_index :id
  cache_index :email, unique: true
  cache_index :confirmation_token, unique: true
  cache_index :reset_password_token, unique: true
  cache_index :plan_id

  # Cache associations
  cache_has_many :restaurants, embed: :ids
  cache_has_many :userplans, embed: :ids
  cache_has_many :testimonials, embed: :ids
  cache_has_many :employees, embed: :ids
  cache_has_one :onboarding_session, embed: :id
  cache_belongs_to :plan

  before_validation :assign_default_plan, on: :create
  after_create :setup_onboarding_session
  # Cache invalidation hooks
  after_update :invalidate_user_caches

  def onboarding_complete?
    onboarding_session&.completed?
  end

  def onboarding_progress
    return 0 unless onboarding_session

    onboarding_session.progress_percentage
  end

  def needs_onboarding?
    !onboarding_complete? && restaurants.empty?
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def name=(full_name)
    parts = full_name.to_s.split(' ', 2)
    self.first_name = parts[0]
    self.last_name = parts[1] if parts.length > 1
  end

  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)

    user ||= find_by(email: auth.info.email)&.tap do |u|
      if u.provider.blank?
        u.update(provider: auth.provider, uid: auth.uid)
      end
    end

    user ||= create!(
      first_name: (auth.info.first_name.presence || auth.info.name.to_s.split(' ').first),
      last_name: (auth.info.last_name.presence || auth.info.name.to_s.split(' ', 2).last),
      email: auth.info.email,
      password: Devise.friendly_token[0, 32],
      provider: auth.provider,
      uid: auth.uid
    )

    user
  end

  private

  def setup_onboarding_session
    OnboardingSession.create!(user: self, status: :started)
  end

  def assign_default_plan
    # Assign a default plan if no plan is set
    return if plan.present?

    # Try to find the cheapest plan (starter) or fall back to first plan
    default_plan = Plan.where(key: 'plan.starter.key').first ||
                   Plan.order(:pricePerMonth).first ||
                   Plan.first
    self.plan = default_plan if default_plan
  end

  def invalidate_user_caches
    AdvancedCacheService.invalidate_user_caches(id)
  end
end
