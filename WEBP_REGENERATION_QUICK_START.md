# WebP Regeneration - Quick Start

## 🚀 Run in Production (Easiest Method)

```bash
# Make script executable (first time only)
chmod +x scripts/regenerate_webp_production.sh

# Run the script
./scripts/regenerate_webp_production.sh
```

That's it! The script will:
1. ✅ Check current WebP status
2. ✅ Queue background jobs to regenerate WebP derivatives
3. ✅ Show monitoring instructions

**Note:** This uses Sidekiq background jobs, so processing happens asynchronously.

---

## 📋 Manual Commands (If you prefer)

### Check WebP Statistics
```bash
heroku run rake images:webp_stats --app smart-menus
```

### Regenerate with WebP (Background Jobs - Recommended)
```bash
heroku run rake images:regenerate_with_webp --app smart-menus
```
This queues jobs for all menus. Jobs are processed by Sidekiq workers.

### Convert Menu Items Synchronously
```bash
heroku run rake images:convert_to_webp --app smart-menus
```
This processes menu items one-by-one in the foreground (slower but immediate).

---

## 🔍 What Gets Processed?

**Using `images:regenerate_with_webp` (Background Jobs):**
- All menu items across all menus
- Jobs are queued per menu and processed by Sidekiq workers
- Processing happens in the background

**Using `images:convert_to_webp` (Synchronous):**
- Only menu items
- Processes one-by-one in the foreground
- Shows real-time progress

---

## ⏱️ Expected Time

**Background Jobs (`regenerate_with_webp`):**
- Depends on Sidekiq worker count
- Multiple images processed in parallel
- Check Sidekiq dashboard for progress

**Synchronous (`convert_to_webp`):**
- ~2-5 seconds per image
- For 100 images: ~5-10 minutes
- For 500 images: ~20-40 minutes
- For 1000 images: ~30-60 minutes

---

## 📊 Monitor Progress

### Check Sidekiq Dashboard
Access your Sidekiq dashboard to see job progress:
```
https://your-app.herokuapp.com/sidekiq
```

### Check Statistics
```bash
heroku run rake images:webp_stats --app smart-menus
```

### Verify a Sample Image
```bash
heroku run rails console --app smart-menus
```

In console:
```ruby
mi = Menuitem.where.not(image_data: nil).first
mi.image_attacher.derivatives.keys
# Should see: [:thumb, :medium, :large, :thumb_webp, :medium_webp, :large_webp]

# Check WebP URL
mi.image_attacher.derivatives[:medium_webp].url
```

---

## 📚 Available Rake Tasks

- `rake images:webp_stats` - Show WebP conversion statistics
- `rake images:regenerate_with_webp` - Queue background jobs for all menus
- `rake images:convert_to_webp` - Synchronously convert menu items

---

## ⚠️ Important Notes

1. **Background Jobs** - The recommended method uses Sidekiq background jobs
2. **Sidekiq Workers** - Ensure you have Sidekiq workers running on Heroku
3. **Off-Peak Hours** - Run during low-traffic periods
4. **Monitor Progress** - Check Sidekiq dashboard for job status

---

## 🆘 Quick Troubleshooting

**Jobs not processing?**
- Check Sidekiq workers are running: `heroku ps --app smart-menus`
- Check Sidekiq dashboard for errors
- Ensure Redis is connected

**Want immediate results?**
Use the synchronous task instead:
```bash
heroku run rake images:convert_to_webp --app smart-menus
```

**Check job status:**
```bash
heroku run rails console --app smart-menus
```
Then:
```ruby
Sidekiq::Queue.new('default').size  # Jobs waiting
Sidekiq::Stats.new.processed        # Jobs completed
```

---

**Ready to go?** Just run: `./scripts/regenerate_webp_production.sh`
