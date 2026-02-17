module OnboardingHelper
  # Onboarding is now a single step (account details + restaurant name).
  # The go-live checklist on the restaurant edit page is the canonical
  # onboarding experience after the initial step.
  #
  # Legacy multi-step helpers (step_title, progress_percentage,
  # step_completed?, next_step) were removed — they referenced a
  # 4-step wizard that no longer exists.
end
