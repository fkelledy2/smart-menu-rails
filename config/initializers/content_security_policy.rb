# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    # unsafe_eval removed. unsafe_inline retained pending migration of remaining
    # inline scripts to Stimulus controllers — track in improvements.md #8.
    policy.script_src  :self, :unsafe_inline, :https
    policy.style_src   :self, :unsafe_inline, :https
    policy.connect_src :self, :https, 'wss:', 'ws:'
    policy.frame_src       :self, 'https://js.stripe.com', 'https://hooks.stripe.com'
    policy.frame_ancestors :self
    policy.base_uri    :self
    policy.form_action :self, :https

    # Report violations to Sentry (set CSP_REPORT_URI in production env)
    policy.report_uri ENV['CSP_REPORT_URI'] if ENV['CSP_REPORT_URI'].present?
  end

  # Enforced — policy is active, not report-only.
  config.content_security_policy_report_only = false
end
