# frozen_string_literal: true

namespace :images do
  desc "Backfill WebP and card_webp derivatives for all existing images"
  task backfill_derivatives: :environment do
    models = [
      { class: Menuitem, scope: -> { Menuitem.where.not(image_data: nil) } },
      { class: Menusection, scope: -> { Menusection.where.not(image_data: nil) } },
      { class: Restaurant, scope: -> { Restaurant.where.not(image_data: nil) } },
    ]

    total = 0
    enqueued = 0

    models.each do |model_config|
      klass = model_config[:class]
      scope = model_config[:scope].call

      count = scope.count
      total += count
      puts "#{klass.name}: #{count} records with images"

      scope.find_each(batch_size: 50) do |record|
        # Check if card_webp derivative already exists (skip if already backfilled)
        attacher = record.image_attacher
        if attacher.derivatives&.key?(:card_webp)
          next
        end

        BackfillImageDerivativesJob.perform_later(klass.name, record.id)
        enqueued += 1
        print "." if (enqueued % 10).zero?
      end
      puts
    end

    puts "\nDone. #{enqueued} jobs enqueued out of #{total} total records with images."
    puts "Jobs will process in the background via Sidekiq."
  end

  desc "Regenerate derivatives for a single record (e.g. rake images:regenerate CLASS=Menuitem ID=123)"
  task regenerate: :environment do
    klass = ENV.fetch('CLASS', 'Menuitem').constantize
    id = ENV.fetch('ID').to_i
    record = klass.find(id)
    attacher = record.image_attacher

    puts "Before: #{attacher.derivatives.keys.sort}"
    attacher.create_derivatives(force: true)
    attacher.atomic_persist
    puts "After:  #{attacher.derivatives.keys.sort}"
    puts "Done."
  end

  desc "Report on derivative coverage across all image-bearing models"
  task derivative_report: :environment do
    models = [Menuitem, Menusection, Restaurant]
    expected_keys = %i[thumb medium large card_webp thumb_webp medium_webp large_webp].sort

    models.each do |klass|
      scope = klass.where.not(image_data: nil)
      total = scope.count
      complete = 0
      missing_card_webp = 0
      missing_any_webp = 0
      no_derivatives = 0

      scope.find_each(batch_size: 100) do |record|
        derivs = record.image_attacher.derivatives
        if derivs.blank?
          no_derivatives += 1
          next
        end

        keys = derivs.keys.map(&:to_sym).sort
        complete += 1 if (expected_keys - keys).empty?
        missing_card_webp += 1 unless derivs.key?(:card_webp)
        missing_any_webp += 1 unless derivs.key?(:thumb_webp) && derivs.key?(:medium_webp) && derivs.key?(:large_webp)
      end

      puts "#{klass.name}: #{total} images"
      puts "  Complete (all 7 derivatives): #{complete}"
      puts "  Missing card_webp:            #{missing_card_webp}"
      puts "  Missing any WebP:             #{missing_any_webp}"
      puts "  No derivatives at all:        #{no_derivatives}"
      puts
    end
  end
end
