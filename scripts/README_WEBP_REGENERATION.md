# WebP Derivative Regeneration Guide

This guide explains how to regenerate WebP derivatives for all existing images in production.

## Overview

The application uses Shrine with the `ImageUploader` to manage images. Each image should have the following derivatives:

**Original Format (PNG/JPEG):**
- `thumb` - 200x200px
- `medium` - 600x480px
- `large` - 1000x800px

**WebP Format (for better performance):**
- `thumb_webp` - 200x200px
- `medium_webp` - 600x480px
- `large_webp` - 1000x800px

## Available Rake Tasks

### 1. Check WebP Status
Check how many images have WebP derivatives:

```bash
# Local
rake images:check_webp_status

# Heroku
heroku run rake images:check_webp_status --app smart-menus
```

### 2. Regenerate Missing WebP Derivatives
Generate WebP derivatives only for images that don't have them:

```bash
# Local
rake images:regenerate_webp

# Heroku
heroku run rake images:regenerate_webp --app smart-menus
```

This task will:
- ✅ Skip images that already have WebP derivatives
- ✅ Generate WebP derivatives for images that don't have them
- ✅ Show progress and summary
- ✅ Handle errors gracefully

### 3. Force Regenerate ALL Derivatives
Force regenerate all derivatives (including existing ones):

```bash
# Local
rake images:force_regenerate_all

# Heroku
heroku run rake images:force_regenerate_all --app smart-menus
```

⚠️ **Warning:** This will regenerate ALL derivatives, even if they already exist. Use this only if you need to update the quality settings or fix corrupted derivatives.

## Quick Start - Production

### Option 1: Using the Shell Script (Recommended)

```bash
# Make the script executable
chmod +x scripts/regenerate_webp_production.sh

# Run the script (it will prompt for confirmation)
./scripts/regenerate_webp_production.sh

# Or specify a different Heroku app name
./scripts/regenerate_webp_production.sh your-app-name
```

The script will:
1. Check current WebP status
2. Regenerate missing WebP derivatives
3. Verify the results

### Option 2: Manual Commands

```bash
# 1. Check current status
heroku run rake images:check_webp_status --app smart-menus

# 2. Regenerate WebP derivatives
heroku run rake images:regenerate_webp --app smart-menus

# 3. Verify results
heroku run rake images:check_webp_status --app smart-menus
```

## Models Affected

The following models use `ImageUploader` and will be processed:

1. **Menuitem** - Menu item images
2. **Restaurant** - Restaurant logos/images
3. **Menu** - Menu cover images
4. **Menusection** - Menu section images

## Performance Considerations

### Processing Time
- Each image takes approximately 2-5 seconds to process
- For 1000 images, expect ~30-60 minutes total processing time
- The task shows progress every 10 records

### Heroku Dyno Timeout
- Heroku has a 30-minute timeout for one-off dynos
- If you have many images (>500), consider running in batches:

```bash
# Process only Menu Items
heroku run rails runner "Menuitem.where.not(image_data: nil).find_each { |m| m.image_attacher.create_derivatives; m.image_attacher.atomic_persist }" --app smart-menus

# Process only Restaurants
heroku run rails runner "Restaurant.where.not(image_data: nil).find_each { |r| r.image_attacher.create_derivatives; r.image_attacher.atomic_persist }" --app smart-menus
```

### Background Processing
For large batches, consider using the existing job:

```bash
heroku run rails runner "Menuitem.where.not(image_data: nil).find_each { |m| GenerateImageDerivativesJob.perform_later(m.class.name, m.id) }" --app smart-menus
```

This will queue the jobs in Sidekiq for background processing.

## Monitoring Progress

### Check Sidekiq Queue
If using background jobs:

```bash
heroku run rails console --app smart-menus
```

Then in the console:
```ruby
# Check queue size
Sidekiq::Queue.new('default').size

# Check processed count
Sidekiq::Stats.new.processed
```

### Check Logs
```bash
heroku logs --tail --app smart-menus
```

## Troubleshooting

### Error: "No image file"
- The record has `image_data` but the actual file is missing from storage
- This usually means the file was deleted from S3/storage
- The task will skip these records

### Error: "ImageProcessing failed"
- ImageMagick or libvips might be missing dependencies
- Check Heroku buildpacks: `heroku buildpacks --app smart-menus`
- Ensure you have the ImageMagick buildpack

### Memory Issues
If you encounter memory issues on Heroku:

```bash
# Use a larger dyno temporarily
heroku run:detached rake images:regenerate_webp --size=performance-l --app smart-menus
```

## Verification

After regeneration, verify the results:

```bash
# Check status
heroku run rake images:check_webp_status --app smart-menus

# Check a specific record in console
heroku run rails console --app smart-menus
```

In the console:
```ruby
# Check a menu item
mi = Menuitem.first
mi.image_attacher.derivatives.keys
# Should include: [:thumb, :medium, :large, :thumb_webp, :medium_webp, :large_webp]

# Check WebP URLs
mi.image_attacher.derivatives[:thumb_webp].url
mi.image_attacher.derivatives[:medium_webp].url
mi.image_attacher.derivatives[:large_webp].url
```

## Cost Considerations

### Storage Costs
- Each image will have 6 derivatives instead of 3
- WebP files are typically 25-35% smaller than JPEG/PNG
- Net storage increase: ~50-75% (3 new files that are smaller)

### Processing Costs
- One-time processing cost for regeneration
- Future uploads automatically generate WebP derivatives
- Consider running during off-peak hours

## Best Practices

1. **Test locally first** - Run on a local database copy to estimate time
2. **Check status before** - Know how many images need processing
3. **Monitor progress** - Watch logs during processing
4. **Verify after** - Check status and sample images after completion
5. **Schedule wisely** - Run during low-traffic periods
6. **Use background jobs** - For large batches, queue jobs instead of synchronous processing

## Support

If you encounter issues:
1. Check the Heroku logs: `heroku logs --tail --app smart-menus`
2. Verify ImageMagick is available: `heroku run convert --version --app smart-menus`
3. Check Shrine configuration in `config/initializers/shrine.rb`
4. Review the ImageUploader at `app/uploaders/image_uploader.rb`
