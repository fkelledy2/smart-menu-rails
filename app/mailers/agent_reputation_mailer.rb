# frozen_string_literal: true

# AgentReputationMailer notifies restaurant managers/owners when the Reputation
# & Feedback Agent has processed a negative signal and produced a recovery draft
# requiring their review. Uses the branded mailer layout.
class AgentReputationMailer < ApplicationMailer
  SIGNAL_LABELS = {
    'rating.low' => 'Low rating',
    'complaint.submitted' => 'Customer complaint',
    'review.received' => 'New review',
    'payment.abandoned' => 'Abandoned payment',
  }.freeze

  # @param restaurant  [Restaurant]
  # @param artifact    [AgentArtifact] — type: reputation_recovery
  # @param recipient   [User]
  # @param severity    [String] low/medium/high
  # @param signal_type [String] rating.low etc.
  # @param systemic_issue [String, nil] advisory note if pattern detected
  def reputation_alert(restaurant:, artifact:, recipient:, severity:, signal_type:, systemic_issue: nil)
    @restaurant    = restaurant
    @artifact      = artifact
    @recipient     = recipient
    @severity      = severity.to_s
    @signal_type   = signal_type.to_s
    @systemic_issue = systemic_issue
    @signal_label = SIGNAL_LABELS.fetch(@signal_type, 'Customer feedback')

    run = artifact.agent_workflow_run
    @review_url = reputation_review_restaurant_agent_workbench_url(@restaurant, run)

    subject_prefix = case @severity
                     when 'high'   then '[Action Required]'
                     when 'medium' then '[Review Soon]'
                     else               '[FYI]'
                     end

    mail(
      to: recipient.email,
      subject: "#{subject_prefix} #{@signal_label} — #{@restaurant.name}",
    )
  end
end
