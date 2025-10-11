class OnboardingSessionPolicy < ApplicationPolicy
  def show?
    # Users can only access their own onboarding session
    record.user == user
  end

  def update?
    # Users can only update their own onboarding session
    record.user == user
  end

  class Scope < Scope
    def resolve
      # Users can only see their own onboarding sessions
      scope.where(user: user)
    end
  end
end
