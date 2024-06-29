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
    cache: Shrine::Storage::S3.new( bucket: "bucketeer-965413d8-bbfb-447a-b727-c2eb2ed49fb1", region: "eu-west-1", access_key_id: "AKIAVVKH7VVUJUEUKY2R", secret_access_key: "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"),
    store: Shrine::Storage::S3.new( bucket: "bucketeer-965413d8-bbfb-447a-b727-c2eb2ed49fb1", region: "eu-west-1", access_key_id: "AKIAVVKH7VVUJUEUKY2R", secret_access_key: "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")
  }
end
Shrine.plugin :activerecord # loads Active Record integration
Shrine.plugin :cached_attachment_data # enables retaining cached file across form redisplays
Shrine.plugin :restore_cached_data  # extracts metadata for assigned cached files
Shrine.plugin :validation_helpers
Shrine.plugin :validation
