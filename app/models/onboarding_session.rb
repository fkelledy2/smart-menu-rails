class OnboardingSession < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :restaurant, optional: true
  belongs_to :menu, optional: true
  
  # Track completion state
  enum status: {
    started: 0,
    account_created: 1, 
    restaurant_details: 2,
    plan_selected: 3,
    menu_created: 4,
    completed: 5
  }
  
  # Store wizard data as JSON
  serialize :wizard_data, coder: JSON
  
  # Wizard data accessors
  def restaurant_name
    wizard_data&.dig('restaurant_name')
  end
  
  def restaurant_name=(value)
    self.wizard_data = (wizard_data || {}).merge('restaurant_name' => value)
  end
  
  def restaurant_type
    wizard_data&.dig('restaurant_type')
  end
  
  def restaurant_type=(value)
    self.wizard_data = (wizard_data || {}).merge('restaurant_type' => value)
  end
  
  def cuisine_type
    wizard_data&.dig('cuisine_type')
  end
  
  def cuisine_type=(value)
    self.wizard_data = (wizard_data || {}).merge('cuisine_type' => value)
  end
  
  def location
    wizard_data&.dig('location')
  end
  
  def location=(value)
    self.wizard_data = (wizard_data || {}).merge('location' => value)
  end
  
  def phone
    wizard_data&.dig('phone')
  end
  
  def phone=(value)
    self.wizard_data = (wizard_data || {}).merge('phone' => value)
  end
  
  def selected_plan_id
    wizard_data&.dig('selected_plan_id')
  end
  
  def selected_plan_id=(value)
    self.wizard_data = (wizard_data || {}).merge('selected_plan_id' => value)
  end
  
  def menu_name
    wizard_data&.dig('menu_name')
  end
  
  def menu_name=(value)
    self.wizard_data = (wizard_data || {}).merge('menu_name' => value)
  end
  
  def menu_items
    wizard_data&.dig('menu_items') || []
  end
  
  def menu_items=(value)
    self.wizard_data = (wizard_data || {}).merge('menu_items' => value)
  end
  
  # Progress calculation
  def progress_percentage
    (status_before_type_cast + 1) * 20 # 20% per step
  end
  
  # Validation helpers
  def step_valid?(step)
    case step
    when 1
      user.present? && user.name.present? && user.email.present?
    when 2
      restaurant_name.present? && restaurant_type.present? && cuisine_type.present?
    when 3
      selected_plan_id.present?
    when 4
      menu_name.present? && menu_items.any?
    else
      true
    end
  end
end
