# Configure AWS SDK SSL CA bundle for environments that use AWS services.
#
# This avoids SSL verification failures on some local dev setups where Ruby/OpenSSL
# doesn't automatically find the system CA store (common on macOS depending on Ruby install).
#
# IMPORTANT:
# - We do NOT disable SSL verification.
# - Production should typically provide proper CA roots via the OS image.

begin
  require 'aws-sdk-core'

  ca_bundle = ENV['AWS_CA_BUNDLE'].presence || ENV['SSL_CERT_FILE'].presence

  if ca_bundle.blank?
    [
      '/etc/ssl/cert.pem',
      '/usr/local/etc/openssl@3/cert.pem',
      '/opt/homebrew/etc/openssl@3/cert.pem',
      '/usr/local/etc/openssl/cert.pem',
      '/opt/homebrew/etc/openssl/cert.pem',
    ].each do |p|
      if File.exist?(p)
        ca_bundle = p
        break
      end
    end
  end

  Aws.config.update(ssl_ca_bundle: ca_bundle) if ca_bundle.present?
rescue LoadError
  # aws-sdk not available; nothing to configure
end
