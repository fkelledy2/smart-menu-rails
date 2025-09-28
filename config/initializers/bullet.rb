# Bullet gem configuration for N+1 query detection
# This initializer provides additional configuration beyond environment-specific settings

if defined?(Bullet)
  # Add specific methods to skip if they have intentional N+1 queries
  # Example: Bullet.add_safelist type: :n_plus_one_query, class_name: 'User', association: :posts

  # Skip counter cache suggestions for certain associations that don't need caching
  # Example: Bullet.add_safelist type: :counter_cache, class_name: 'User', association: :posts

  # Skip unused eager loading warnings for associations that are conditionally used
  # SmartmenusController loads menu associations conditionally in show action
  Bullet.add_safelist type: :unused_eager_loading, class_name: 'Menu', association: :menusections
  Bullet.add_safelist type: :unused_eager_loading, class_name: 'Menu', association: :menuavailabilities
  Bullet.add_safelist type: :unused_eager_loading, class_name: 'Menu', association: :menuitems
  
  # Custom notification handler for development
  if Rails.env.development?
    # You can add custom notification handling here
    # For example, sending notifications to Slack, email, etc.
  end
  
  # Custom notification handler for test environment
  if Rails.env.test?
    # In test environment, we want to be strict about N+1 queries
    # The configuration in test.rb already sets Bullet.raise = true
    
    # You can add test-specific exclusions here if needed
    # For example, certain test scenarios that intentionally create N+1 queries
  end
end
