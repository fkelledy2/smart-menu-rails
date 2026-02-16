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
    policy.script_src  :self, :unsafe_inline, :unsafe_eval, :https
    policy.style_src   :self, :unsafe_inline, :https
    policy.connect_src :self, :https, 'wss:', 'ws:'
    policy.frame_ancestors :self
    policy.base_uri    :self
    policy.form_action :self, :https
  end

  # Start in report-only mode to monitor violations without breaking functionality.
  # Once violations are reviewed and resolved, switch to enforcing mode by removing this line.
  config.content_security_policy_report_only = true
end
