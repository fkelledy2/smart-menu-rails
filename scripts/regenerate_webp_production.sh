#!/bin/bash

# =============================================================================
# Production Image Derivative Backfill Script
# =============================================================================
#
# Regenerates all Shrine image derivatives (including card_webp, thumb_webp,
# medium_webp, large_webp) for every image in the database.
#
# This is needed after adding new derivative sizes or after discovering that
# GenerateImageDerivativesJob was previously only generating a subset.
#
# Usage:
#   ./scripts/regenerate_webp_production.sh              # default app: smart-menus
#   ./scripts/regenerate_webp_production.sh my-app       # custom app name
#   ./scripts/regenerate_webp_production.sh --report-only # just show stats
#
# Rake tasks used:
#   rake images:derivative_report    — show derivative coverage stats
#   rake images:backfill_derivatives — enqueue Sidekiq jobs for missing derivatives
#   rake images:regenerate CLASS=Menuitem ID=123 — regenerate a single record
# =============================================================================

set -euo pipefail

APP_NAME="${1:-smart-menus}"
REPORT_ONLY=false

if [[ "${1:-}" == "--report-only" ]]; then
  REPORT_ONLY=true
  APP_NAME="${2:-smart-menus}"
fi

# ---------- preflight checks ----------

if ! command -v heroku &> /dev/null; then
  echo "Error: Heroku CLI is not installed."
  echo "Install: https://devcenter.heroku.com/articles/heroku-cli"
  exit 1
fi

echo "╔══════════════════════════════════════════════════════╗"
echo "║  Image Derivative Backfill — Production             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Heroku app:  $APP_NAME"
echo "  Mode:        $(if $REPORT_ONLY; then echo 'REPORT ONLY'; else echo 'BACKFILL'; fi)"
echo ""

# ---------- Step 1: derivative coverage report ----------

echo "━━━ Step 1: Current derivative coverage ━━━"
echo ""
heroku run --app "$APP_NAME" -- bin/rails runner '
  models = [Menuitem, Menusection, Restaurant]
  expected = %i[thumb medium large card_webp thumb_webp medium_webp large_webp]

  models.each do |klass|
    scope = klass.where.not(image_data: nil)
    total = scope.count
    complete = 0
    missing_card = 0
    missing_webp = 0
    no_derivs = 0

    scope.find_each(batch_size: 100) do |r|
      d = r.image_attacher.derivatives
      if d.blank?
        no_derivs += 1
        next
      end
      keys = d.keys.map(&:to_sym)
      complete += 1 if (expected - keys).empty?
      missing_card += 1 unless keys.include?(:card_webp)
      missing_webp += 1 unless keys.include?(:thumb_webp) && keys.include?(:medium_webp) && keys.include?(:large_webp)
    end

    puts "#{klass.name}: #{total} images"
    puts "  ✅ Complete (all 7 derivatives): #{complete}"
    puts "  ⚠️  Missing card_webp:           #{missing_card}"
    puts "  ⚠️  Missing any WebP:            #{missing_webp}"
    puts "  ❌ No derivatives at all:        #{no_derivs}"
    puts "  📦 Need backfill:                #{total - complete}"
    puts ""
  end
'

if $REPORT_ONLY; then
  echo "Report complete. Re-run without --report-only to backfill."
  exit 0
fi

# ---------- Step 2: confirm ----------

echo ""
echo "━━━ Step 2: Confirm backfill ━━━"
echo ""
echo "This will enqueue Sidekiq background jobs to regenerate derivatives"
echo "for every image that is missing the card_webp derivative."
echo ""
echo "Each job downloads the original image from S3, generates 7 derivatives"
echo "(thumb, medium, large + 4 WebP variants), and uploads them back."
echo ""
echo "⏱  Estimated time: ~2-5 seconds per image (depends on S3 latency)."
echo ""
read -p "Proceed? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ---------- Step 3: enqueue backfill jobs ----------

echo ""
echo "━━━ Step 3: Enqueuing backfill jobs ━━━"
echo ""
heroku run --app "$APP_NAME" -- bin/rails runner '
  models = [
    { klass: Menuitem,    scope: -> { Menuitem.where.not(image_data: nil) } },
    { klass: Menusection, scope: -> { Menusection.where.not(image_data: nil) } },
    { klass: Restaurant,  scope: -> { Restaurant.where.not(image_data: nil) } },
  ]

  total = 0
  enqueued = 0

  models.each do |cfg|
    klass = cfg[:klass]
    scope = cfg[:scope].call
    count = scope.count
    total += count
    skipped = 0

    scope.find_each(batch_size: 50) do |record|
      if record.image_attacher.derivatives&.key?(:card_webp)
        skipped += 1
        next
      end
      BackfillImageDerivativesJob.perform_later(klass.name, record.id)
      enqueued += 1
    end

    puts "#{klass.name}: #{count} images, #{enqueued} enqueued, #{skipped} already complete"
  end

  puts ""
  puts "Total: #{enqueued} jobs enqueued out of #{total} images."
  puts "Jobs will process via Sidekiq in the background."
'

# ---------- Step 4: monitoring instructions ----------

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✅ Backfill jobs enqueued!                         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Monitor progress:"
echo ""
echo "  1. Sidekiq dashboard:"
echo "     https://$APP_NAME.herokuapp.com/admin/sidekiq"
echo ""
echo "  2. Re-run the report to check coverage:"
echo "     ./scripts/regenerate_webp_production.sh --report-only $APP_NAME"
echo ""
echo "  3. Check a single image:"
echo "     heroku run --app $APP_NAME -- bin/rails runner \\"
echo "       'puts Menuitem.find(ID).image_attacher.derivatives.keys.sort'"
echo ""
echo "  4. Regenerate a single record manually:"
echo "     heroku run --app $APP_NAME -- bin/rails runner \\"
echo "       'rake images:regenerate CLASS=Menuitem ID=123'"
echo ""
