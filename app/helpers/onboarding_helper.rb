module OnboardingHelper
  def onboarding_step_title(step)
    case step.to_s
    when '1', 'restaurant'
      'Restaurant Information'
    when '2', 'menu'
      'Menu Setup'
    when '3', 'payment'
      'Payment Configuration'
    when '4', 'complete'
      'Setup Complete'
    else
      'Onboarding'
    end
  end

  def onboarding_progress_percentage(step)
    step_number = case step.to_s
                  when '1', 'restaurant'
                    1
                  when '2', 'menu'
                    2
                  when '3', 'payment'
                    3
                  when '4', 'complete'
                    4
                  else
                    0
                  end

    ((step_number.to_f / 4) * 100).round
  end

  def onboarding_step_completed?(step, user)
    return false unless user

    case step.to_s
    when '1', 'restaurant'
      Restaurant.exists?(user_id: user.id)
    when '2', 'menu'
      Menu.joins(:restaurant).exists?(restaurants: { user_id: user.id })
    when '3', 'payment'
      # Assume payment is configured if user has active restaurants
      Restaurant.exists?(user_id: user.id, status: 'active')
    else
      false
    end
  end

  def next_onboarding_step(current_step)
    case current_step.to_s
    when '1', 'restaurant'
      '2'
    when '2', 'menu'
      '3'
    when '3', 'payment'
      '4'
    else
      '1'
    end
  end
end
