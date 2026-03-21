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
    # unsafe_inline retained: ~30 inline <script> blocks across views require nonce
    # migration before this can be removed. Nonce infrastructure is enabled below.
    # See docs/pentest_remediation.md Finding 3 for the full migration plan.
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

  # Nonce generation — Rails injects a unique per-request nonce into script tags
  # that include nonce: content_security_policy_nonce. Once all inline <script>
  # blocks have been migrated to use nonces, :unsafe_inline can be removed above.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
