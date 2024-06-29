require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/memory"
require "shrine/storage/s3"

if  Rails.env.test?
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new,
  }
else
  Shrine.storages = {
    cache: Shrine::Storage::S3.new( bucket: "<%= ENV['BUCKETEER_BUCKET_NAME'] %>", region: "<%= ENV['BUCKETEER_AWS_REGION'] %>", access_key_id: "<%= ENV['BUCKETEER_AWS_ACCESS_KEY_ID'] %>", secret_access_key: "<%= ENV['BUCKETEER_AWS_SECRET_ACCESS_KEY'] %>"),
    store: Shrine::Storage::S3.new( bucket: "<%= ENV['BUCKETEER_BUCKET_NAME'] %>", region: "<%= ENV['BUCKETEER_AWS_REGION'] %>", access_key_id: "<%= ENV['BUCKETEER_AWS_ACCESS_KEY_ID'] %>", secret_access_key: "<%= ENV['BUCKETEER_AWS_SECRET_ACCESS_KEY'] %>")

  }
end
Shrine.plugin :activerecord # loads Active Record integration
Shrine.plugin :cached_attachment_data # enables retaining cached file across form redisplays
Shrine.plugin :restore_cached_data  # extracts metadata for assigned cached files
Shrine.plugin :validation_helpers
Shrine.plugin :validation
