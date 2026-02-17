class OnboardingSession < ApplicationRecord
  include IdentityCache

  belongs_to :user, optional: true
  belongs_to :restaurant, optional: true
  belongs_to :menu, optional: true

  # IdentityCache configuration
  cache_index :id
  cache_index :user_id
  cache_index :status

  # Cache associations
  cache_belongs_to :user
  cache_belongs_to :restaurant
  cache_belongs_to :menu

  # Track completion state — simplified to started → completed
  # Legacy values 1-4 may exist in DB but are functionally equivalent to started.
  enum :status, {
    started: 0,
    completed: 5,
  }

  # Store wizard data as JSON (kept for backward compatibility with existing rows)
  serialize :wizard_data, coder: JSON

  # Wizard data accessor — only restaurant_name is still used
  def restaurant_name
    wizard_data&.dig('restaurant_name')
  end

  def restaurant_name=(value)
    self.wizard_data = (wizard_data || {}).dup.merge('restaurant_name' => value)
  end

  # Progress: 0% (started) or 100% (completed)
  def progress_percentage
    completed? ? 100 : 0
  end
end
