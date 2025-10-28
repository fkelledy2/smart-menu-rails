# Hero Images Quick Start Guide

## Overview

The Hero Images system allows admin users to manage the background images displayed in the homepage carousel through a web interface, similar to the testimonials feature.

## Quick Setup

### 1. Run Migration (if not already done)

```bash
bin/rails db:migrate
```

### 2. Seed Initial Images

```bash
# Run just the hero images seed
bin/rails runner "load Rails.root.join('db', 'seeds', 'hero_images.rb')"

# Or run all seeds
bin/rails db:seed
```

This will create 10 pre-approved Pexels images in the database.

### 3. Access Admin Interface

**As an admin user:**

1. Log in to the application
2. Click your profile name in the top-right navbar
3. Select **"Hero Images"** from the dropdown
4. You'll see a table of all hero images with previews

**Or navigate directly to:** `/hero_images`

## Admin Features

### View All Images
- Table view with image previews
- Status badges (Approved/Unapproved)
- Sequence numbers for ordering
- Quick actions (Show, Edit, Delete)

### Add New Image
1. Click "New Hero Image"
2. Enter image URL (from Pexels or other source)
3. Add alt text for accessibility
4. Set sequence number (lower = appears first)
5. Set status to "Approved" to show on homepage
6. Optionally add source URL
7. Click "Save"

### Edit Existing Image
1. Click "Edit" on any image
2. Modify fields as needed
3. Change status to approve/unapprove
4. Click "Save"

### Delete Image
1. Click "Delete" on any image
2. Confirm deletion

## How It Works

### Backend Flow
1. **HomeController** fetches approved images: `@hero_images = HeroImage.approved_for_carousel`
2. **View** passes images to JavaScript via `data-hero-images` attribute
3. **JavaScript** parses images and creates carousel
4. **Fallback**: If no approved images exist, uses hardcoded Pexels images

### Image Selection Priority
1. **Primary**: Database-approved images (admin-controlled)
2. **Fallback**: Hardcoded Pexels images (10 images)

### Randomization
- Images are shuffled on each page load using Fisher-Yates algorithm
- Ensures variety for returning visitors

## Admin Access

### Requirements
- User must be logged in
- User must have `admin: true` in database
- Same access pattern as Testimonials

### Navbar Location
The "Hero Images" link appears in the profile dropdown menu:
- Settings
- Billing (if applicable)
- **--- Admin Section ---**
- Testimonials
- **Hero Images** ← New
- Admin

## Database Schema

```ruby
create_table :hero_images do |t|
  t.string :image_url, null: false      # Full URL to image
  t.string :alt_text                    # Accessibility text
  t.integer :sequence, default: 0       # Display order
  t.integer :status, default: 0         # 0=unapproved, 1=approved
  t.string :source_url                  # Original source link
  t.timestamps
end
```

## Image Requirements

### Recommended Specifications
- **Format**: JPEG or PNG
- **Dimensions**: 1920px width (landscape)
- **Aspect Ratio**: 16:9 or wider
- **File Size**: Optimized for web (< 500KB)
- **Content**: Restaurant scenes with people

### URL Format
- Must be valid HTTP/HTTPS URL
- Should be publicly accessible
- Recommended sources: Pexels, Unsplash, or your own CDN

## Testing

All functionality is fully tested:
- ✅ 18 Model tests
- ✅ 21 Controller tests
- ✅ 18 Policy tests
- **Total: 57 tests, 100% passing**

```bash
# Run all hero image tests
bin/rails test test/models/hero_image_test.rb \
                test/controllers/hero_images_controller_test.rb \
                test/policies/hero_image_policy_test.rb
```

## Troubleshooting

### Images Not Showing on Homepage

**Check:**
1. Are images approved? (Status should be "Approved")
2. Run in Rails console: `HeroImage.approved.count` (should be > 0)
3. Check browser console for JavaScript errors
4. Verify images load correctly (check URLs)

### Can't Access /hero_images

**Check:**
1. Are you logged in?
2. Is your user an admin? Run: `User.find_by(email: 'your@email.com').admin?`
3. Should return `true`

### Seed File Not Working

**Check:**
1. Migration has been run: `bin/rails db:migrate:status`
2. Look for `CreateHeroImages` migration
3. Re-run seed: `bin/rails runner "load Rails.root.join('db', 'seeds', 'hero_images.rb')"`

## Common Tasks

### Check Current Images
```ruby
# Rails console
HeroImage.all.pluck(:sequence, :status, :alt_text)
```

### Approve All Images
```ruby
# Rails console
HeroImage.update_all(status: 1)
```

### Resequence Images
```ruby
# Rails console
HeroImage.approved.ordered.each_with_index do |img, idx|
  img.update(sequence: idx + 1)
end
```

### Clear All Images
```ruby
# Rails console (use with caution!)
HeroImage.destroy_all
```

## Routes

```
GET    /hero_images          # List all images
GET    /hero_images/new      # New image form
POST   /hero_images          # Create image
GET    /hero_images/:id      # Show image
GET    /hero_images/:id/edit # Edit image form
PATCH  /hero_images/:id      # Update image
DELETE /hero_images/:id      # Delete image
```

## Files Modified/Created

### New Files (18)
- `db/migrate/20251028151017_create_hero_images.rb`
- `db/seeds/hero_images.rb`
- `app/models/hero_image.rb`
- `app/controllers/hero_images_controller.rb`
- `app/policies/hero_image_policy.rb`
- `app/views/hero_images/` (9 view files)
- `test/` (3 test files)
- Documentation files

### Modified Files (7)
- `config/routes.rb` - Added hero_images resource
- `app/controllers/home_controller.rb` - Fetch approved images
- `app/views/home/index.html.erb` - Pass images to JavaScript
- `app/views/shared/_navbar.html.erb` - Added admin menu link
- `app/javascript/modules/hero_carousel.js` - Use backend images
- `config/locales/shared.en.yml` - Added translation
- `config/locales/shared.it.yml` - Added translation
- `db/seeds.rb` - Load hero images seed

## Next Steps

1. ✅ Run migration
2. ✅ Seed initial images
3. ✅ Log in as admin user
4. ✅ Navigate to Hero Images
5. ✅ Verify images appear in table
6. ✅ Check homepage carousel
7. ✅ Add/edit/delete images as needed

## Support

For detailed documentation, see:
- **HERO_IMAGE_ADMIN_SYSTEM.md** - Complete system documentation
- **HERO_CAROUSEL_IMPLEMENTATION.md** - Carousel technical details

## Summary

The Hero Images system provides admin users with full control over homepage carousel images through a user-friendly web interface. It follows the same access pattern as Testimonials, includes comprehensive testing, and provides fallback support for seamless operation.
