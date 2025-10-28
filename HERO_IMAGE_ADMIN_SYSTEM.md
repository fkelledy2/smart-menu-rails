# Hero Image Admin Management System

## Overview

The Hero Image Admin Management System provides admin users with full control over which images appear in the homepage hero carousel. This replaces the hardcoded Pexels image URLs with a database-driven, admin-approved system.

## Features

- **Admin-Only Access**: Only users with `admin: true` can manage hero images
- **Approval Workflow**: Images must be approved before appearing on the homepage
- **Sequence Control**: Admins can control the display order of images
- **Fallback Support**: If no approved images exist, the system falls back to hardcoded Pexels images
- **Full CRUD Operations**: Create, read, update, and delete hero images
- **Image Preview**: Visual preview of images in the admin interface
- **Source Tracking**: Optional field to track the original source of images

## Architecture

### Database Schema

**Table: `hero_images`**

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PRIMARY KEY | Auto-incrementing ID |
| image_url | string | NOT NULL | Full URL to the image |
| alt_text | string | nullable | Accessibility text |
| sequence | integer | DEFAULT 0 | Display order (lower = first) |
| status | integer | DEFAULT 0, NOT NULL | 0=unapproved, 1=approved |
| source_url | string | nullable | Link to original source |
| created_at | timestamp | NOT NULL | Record creation time |
| updated_at | timestamp | NOT NULL | Last update time |

**Indexes:**
- `index_hero_images_on_status`
- `index_hero_images_on_sequence`

### Models

**HeroImage** (`app/models/hero_image.rb`)

```ruby
class HeroImage < ApplicationRecord
  include IdentityCache

  enum :status, { unapproved: 0, approved: 1 }

  validates :image_url, presence: true, format: { with: URI regex }
  validates :sequence, numericality: { only_integer: true, >= 0 }
  validates :status, presence: true

  scope :approved, -> { where(status: :approved) }
  scope :ordered, -> { order(:sequence, :created_at) }

  def self.approved_for_carousel
    approved.ordered
  end
end
```

### Controllers

**HeroImagesController** (`app/controllers/hero_images_controller.rb`)

- **Authentication**: Requires user login
- **Authorization**: Admin-only access via Pundit
- **Actions**: Full CRUD (index, show, new, create, edit, update, destroy)
- **Formats**: Supports both HTML and JSON responses
- **Onboarding**: Skips onboarding redirect for admin users

### Policies

**HeroImagePolicy** (`app/policies/hero_image_policy.rb`)

- **index?**: Admin only
- **show?**: Admin only
- **create?**: Admin only
- **update?**: Admin only
- **destroy?**: Admin only
- **Scope**: Returns all images for admins, none for others

### Views

**HTML Views:**
- `index.html.erb`: Table view with image previews, status badges, and actions
- `show.html.erb`: Detailed view with large image preview
- `new.html.erb`: Form for creating new hero images
- `edit.html.erb`: Form for editing existing hero images
- `_form.html.erb`: Shared form partial

**JSON Views:**
- `index.json.jbuilder`: Array of hero images
- `show.json.jbuilder`: Single hero image
- `_hero_image.json.jbuilder`: Hero image partial

### Routes

```ruby
resources :hero_images
```

**Generated Routes:**
- `GET    /hero_images` - List all hero images (admin)
- `GET    /hero_images/new` - New hero image form (admin)
- `POST   /hero_images` - Create hero image (admin)
- `GET    /hero_images/:id` - Show hero image (admin)
- `GET    /hero_images/:id/edit` - Edit hero image form (admin)
- `PATCH  /hero_images/:id` - Update hero image (admin)
- `DELETE /hero_images/:id` - Delete hero image (admin)

## Integration with Homepage

### HomeController

```ruby
def index
  # ...
  @hero_images = HeroImage.approved_for_carousel
  # ...
end
```

### View (index.html.erb)

```erb
<div class="hero-carousel" 
     data-hero-images="<%= @hero_images.map { |img| { url: img.image_url, alt: img.alt_text } }.to_json %>">
```

### JavaScript (hero_carousel.js)

The carousel JavaScript:
1. Checks for `data-hero-images` attribute
2. Parses backend-approved images
3. Randomizes the order using Fisher-Yates shuffle
4. Falls back to hardcoded Pexels images if none exist
5. Creates background layers and starts carousel

## Accessing the Admin Interface

### Navigation

Admin users can access the Hero Images management interface in two ways:

1. **Via Navbar Dropdown**:
   - Click on your profile name in the top-right navbar
   - Select "Hero Images" from the dropdown menu (appears only for admin users)

2. **Direct URL**:
   - Navigate to `/hero_images`
   - Requires admin authentication

The Hero Images link appears in the same dropdown as "Testimonials" and "Admin", following the same access pattern.

## Usage Guide

### For Admin Users

#### Adding a New Hero Image

1. Navigate to `/hero_images`
2. Click "New Hero Image"
3. Fill in the form:
   - **Image URL**: Full URL to the image (required)
   - **Alt Text**: Descriptive text for accessibility
   - **Sequence**: Display order (0 = first)
   - **Status**: Select "Approved" to show on homepage
   - **Source URL**: Optional link to original source
4. Click "Save"

#### Approving an Image

1. Navigate to `/hero_images`
2. Find the unapproved image
3. Click "Edit"
4. Change Status to "Approved"
5. Click "Save"

#### Changing Display Order

1. Navigate to `/hero_images`
2. Click "Edit" on the image
3. Change the Sequence number (lower numbers appear first)
4. Click "Save"

#### Removing an Image

1. Navigate to `/hero_images`
2. Click "Delete" on the image
3. Confirm deletion

### For Developers

#### Seeding Initial Images

The application includes a pre-configured seed file with 10 approved Pexels images:

```bash
# Run the hero images seed file
bin/rails runner "load Rails.root.join('db', 'seeds', 'hero_images.rb')"

# Or run all seeds (includes hero images)
bin/rails db:seed
```

The seed file is located at `db/seeds/hero_images.rb` and includes:
- 10 curated restaurant images from Pexels
- All images pre-approved (status: approved)
- Proper sequencing (1-10)
- Alt text for accessibility
- Source URLs for attribution

**Seed File Features:**
- Uses `find_or_initialize_by` to prevent duplicates
- Provides detailed output for each image
- Shows total and approved image counts
- Idempotent (can be run multiple times safely)

#### Querying Approved Images

```ruby
# Get all approved images in order
HeroImage.approved_for_carousel

# Get count of approved images
HeroImage.approved.count

# Check if any approved images exist
HeroImage.approved.any?
```

## Testing

### Test Coverage

**Model Tests** (`test/models/hero_image_test.rb`):
- ✅ 18 tests covering validations, scopes, and methods
- Tests URL validation, status enums, sequence ordering
- Tests approved_for_carousel class method

**Controller Tests** (`test/controllers/hero_images_controller_test.rb`):
- ✅ 21 tests covering all CRUD operations
- Tests admin authorization for all actions
- Tests both HTML and JSON responses
- Tests create/update with valid and invalid data

**Policy Tests** (`test/policies/hero_image_policy_test.rb`):
- ✅ 18 tests covering all policy methods
- Tests admin vs. regular user vs. guest access
- Tests policy scopes

**Total: 57 tests, 98 assertions, 100% passing**

### Running Tests

```bash
# Run all hero image tests
bin/rails test test/models/hero_image_test.rb test/controllers/hero_images_controller_test.rb test/policies/hero_image_policy_test.rb

# Run specific test file
bin/rails test test/models/hero_image_test.rb

# Run specific test
bin/rails test test/models/hero_image_test.rb:10
```

## Security Considerations

1. **Admin-Only Access**: All hero image management requires admin privileges
2. **URL Validation**: Image URLs must be valid HTTP/HTTPS URLs
3. **Authorization Checks**: Pundit policies enforce access control
4. **Onboarding Skip**: Admin users bypass onboarding for management tasks
5. **XSS Protection**: Image URLs are validated, alt text is escaped in views

## Performance Considerations

1. **IdentityCache**: Model uses IdentityCache for fast lookups
2. **Database Indexes**: Indexes on status and sequence for fast queries
3. **Scoped Queries**: Only approved images are fetched for homepage
4. **Ordered Results**: Database handles sorting, not application
5. **Fallback Images**: Hardcoded fallback prevents empty carousels

## Fallback Behavior

If no approved hero images exist in the database:
1. JavaScript checks for `data-hero-images` attribute
2. Finds no images or empty array
3. Falls back to 10 hardcoded Pexels images
4. Logs fallback usage to console
5. Carousel functions normally with fallback images

## Future Enhancements

Potential improvements for future versions:

1. **Image Upload**: Direct image upload instead of URL entry
2. **Bulk Operations**: Approve/unapprove multiple images at once
3. **Image Validation**: Check if URLs are accessible before saving
4. **Scheduling**: Set start/end dates for seasonal images
5. **A/B Testing**: Track which images perform best
6. **Image Optimization**: Automatic resizing and compression
7. **CDN Integration**: Store images on CDN for better performance
8. **Preview Mode**: Preview carousel before approving images
9. **Analytics**: Track image views and engagement
10. **Categories**: Group images by theme or season

## Troubleshooting

### Images Not Appearing on Homepage

**Check:**
1. Are images approved? (`status: approved`)
2. Are there any approved images? (`HeroImage.approved.any?`)
3. Check browser console for JavaScript errors
4. Verify `data-hero-images` attribute in HTML
5. Check if fallback images are loading

### Admin Can't Access Hero Images

**Check:**
1. Is user marked as admin? (`user.admin?`)
2. Check Pundit policy (`HeroImagePolicy.new(user, HeroImage).index?`)
3. Verify user is logged in
4. Check for authorization errors in logs

### Images Not Displaying Correctly

**Check:**
1. Is image URL valid and accessible?
2. Is image URL HTTPS (not HTTP)?
3. Check image dimensions (should be landscape, ~1920px wide)
4. Verify CORS headers if images are from external source
5. Check browser network tab for failed image loads

## Migration Guide

### From Hardcoded to Database-Driven

1. **Run Migration**: `bin/rails db:migrate`
2. **Seed Initial Images**: Add approved images to database
3. **Test**: Verify images appear on homepage
4. **Monitor**: Check logs for fallback usage
5. **Optimize**: Remove hardcoded images once database is populated

### Rollback Plan

If issues occur:
1. Database migration can be rolled back: `bin/rails db:rollback`
2. Fallback images ensure carousel always works
3. Remove `@hero_images` from HomeController
4. Remove `data-hero-images` from view
5. JavaScript will use fallback images

## Maintenance

### Regular Tasks

1. **Review Images**: Periodically review approved images
2. **Update Sequences**: Adjust order based on performance
3. **Add New Images**: Keep carousel fresh with new content
4. **Remove Old Images**: Delete outdated or low-performing images
5. **Monitor Performance**: Check page load times

### Database Maintenance

```ruby
# Remove unapproved images older than 30 days
HeroImage.where(status: :unapproved).where('created_at < ?', 30.days.ago).destroy_all

# Resequence images
HeroImage.approved.ordered.each_with_index do |img, idx|
  img.update(sequence: idx)
end
```

## API Documentation

### JSON Endpoints

All endpoints require admin authentication.

**GET /hero_images.json**
```json
[
  {
    "id": 1,
    "image_url": "https://...",
    "alt_text": "...",
    "sequence": 0,
    "status": "approved",
    "source_url": "https://...",
    "created_at": "2024-10-28T15:10:17.000Z",
    "updated_at": "2024-10-28T15:10:17.000Z",
    "url": "http://localhost:3000/hero_images/1.json"
  }
]
```

**GET /hero_images/:id.json**
```json
{
  "id": 1,
  "image_url": "https://...",
  "alt_text": "...",
  "sequence": 0,
  "status": "approved",
  "source_url": "https://...",
  "created_at": "2024-10-28T15:10:17.000Z",
  "updated_at": "2024-10-28T15:10:17.000Z",
  "url": "http://localhost:3000/hero_images/1.json"
}
```

**POST /hero_images.json**
```json
{
  "hero_image": {
    "image_url": "https://...",
    "alt_text": "...",
    "sequence": 0,
    "status": "approved",
    "source_url": "https://..."
  }
}
```

## Conclusion

The Hero Image Admin Management System provides a robust, secure, and user-friendly way for administrators to control homepage carousel content. With comprehensive testing, fallback support, and clear documentation, it's production-ready and maintainable.
