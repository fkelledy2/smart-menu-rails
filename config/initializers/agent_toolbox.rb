# frozen_string_literal: true

# Register all available agent tools with the Toolbox.
# Tools are registered at app boot. Individual agents can register additional tools.
Rails.application.config.after_initialize do
  Agents::Toolbox.register(Agents::Tools::ReadRestaurantContext)
  Agents::Toolbox.register(Agents::Tools::SearchMenuItems)
  Agents::Toolbox.register(Agents::Tools::ProposeMenuPatch)
  Agents::Toolbox.register(Agents::Tools::ComposeManagerSummary)
  Agents::Toolbox.register(Agents::Tools::CreateReviewQueueTask)
end
