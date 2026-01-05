require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/memory"

# Use file system for development and test, S3 for production
if Rails.env.test?
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new,
  }
else
  aws_bucket = Rails.application.credentials.dig(:aws, :bucket)
  aws_region = Rails.application.credentials.dig(:aws, :region)
  aws_key = Rails.application.credentials.dig(:aws, :access_key_id)
  aws_secret = Rails.application.credentials.dig(:aws, :secret_access_key)

  use_s3 = aws_bucket.present? && aws_region.present? && aws_key.present? && aws_secret.present?

  if use_s3
    begin
      # Use S3 in production (or if explicitly configured)
      require "shrine/storage/s3"
      require "aws-sdk-s3"

      ca_bundle = ENV['AWS_CA_BUNDLE'].presence || ENV['SSL_CERT_FILE'].presence
      if ca_bundle.blank?
        ['/etc/ssl/cert.pem', '/usr/local/etc/openssl@3/cert.pem', '/opt/homebrew/etc/openssl@3/cert.pem'].each do |p|
          if File.exist?(p)
            ca_bundle = p
            break
          end
        end
      end

      aws_client_options = {
        region:            aws_region,
        access_key_id:     aws_key,
        secret_access_key: aws_secret,
      }
      aws_client_options[:ssl_ca_bundle] = ca_bundle if ca_bundle.present?

      s3_options = {
        bucket: aws_bucket,
        client: Aws::S3::Client.new(**aws_client_options),
      }

      Shrine.storages = {
        cache: Shrine::Storage::S3.new(prefix: "cache", **s3_options),
        store: Shrine::Storage::S3.new(**s3_options),
      }
    rescue LoadError => e
      Rails.logger.warn("[shrine] S3 gems not available (#{e.message}); falling back to FileSystem storage")
      Shrine.storages = {
        cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
        store: Shrine::Storage::FileSystem.new("public", prefix: "uploads"),
      }
    end
  else
    Shrine.storages = {
      cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
      store: Shrine::Storage::FileSystem.new("public", prefix: "uploads"),
    }
  end
end

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data # for retaining the cached file across form redisplays
Shrine.plugin :restore_cached_data # re-extract metadata when attaching a cached file
Shrine.plugin :validation
Shrine.plugin :validation_helpers
Shrine.plugin :remove_attachment

# Create upload directory if it doesn't exist
if Rails.env.development? && Shrine.storages[:store].is_a?(Shrine::Storage::FileSystem)
  FileUtils.mkdir_p(File.join(Rails.root, "public/uploads"))
  FileUtils.mkdir_p(File.join(Rails.root, "public/uploads/cache"))
end
