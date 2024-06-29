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
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new,
  }
end
Shrine.plugin :activerecord # loads Active Record integration
Shrine.plugin :cached_attachment_data # enables retaining cached file across form redisplays
Shrine.plugin :restore_cached_data  # extracts metadata for assigned cached files
Shrine.plugin :validation_helpers
Shrine.plugin :validation
