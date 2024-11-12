require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/memory"
require "shrine/storage/s3"

s3_options = {
  bucket:            Rails.application.credentials.dig(:aws, :bucket), # required
  access_key_id:     Rails.application.credentials.dig(:aws, :access_key_id),
  secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key),
  region:            Rails.application.credentials.dig(:aws, :region),
}

if  Rails.env.test?
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new,
  }
else
  Shrine.storages = {
    cache: Shrine::Storage::S3.new(prefix: "cache", **s3_options),
    store: Shrine::Storage::S3.new(**s3_options),
  }
end
Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data # for retaining the cached file across form redisplays
Shrine.plugin :restore_cached_data # re-extract metadata when attaching a cached file
Shrine.plugin :validation
Shrine.plugin :validation_helpers
Shrine.plugin :remove_attachment
