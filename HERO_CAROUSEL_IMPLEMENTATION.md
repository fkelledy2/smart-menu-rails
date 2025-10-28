# Hero Carousel Implementation - Dissolving Background Images

## Overview
Implemented a CSS dissolve transition carousel for the homepage hero section with independent timers: CTA text changes every 5 seconds and background images change every 10 seconds. Images are sourced from an **admin-controlled database** with fallback to Pexels, randomized on each page load, with CTA overlay positioned at the bottom.

## Admin Management
**NEW**: Hero images are now managed through an admin interface. See [HERO_IMAGE_ADMIN_SYSTEM.md](HERO_IMAGE_ADMIN_SYSTEM.md) for complete documentation on:
- Adding/removing images via admin UI
- Approval workflow
- Image sequencing
- Database schema and API

**Admin URL**: `/hero_images` (admin users only)

## Changes Made

### 1. CSS Updates (`app/assets/stylesheets/pages/_home.scss`)

**Removed:**
- Static background image in `.hero-carousel::before` pseudo-element

**Added:**
- `.hero-background` class for dynamic background layers
- CSS transition: `opacity 2s ease-in-out` for smooth dissolve effect
- `.hero-background.active` class to control visibility

```scss
.hero-background {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-size: cover;
  background-position: center center;
  background-repeat: no-repeat;
  opacity: 0;
  transition: opacity 2s ease-in-out;
  z-index: 0;
  
  &.active {
    opacity: 1;
  }
}
```

### 2. JavaScript Module (`app/javascript/modules/hero_carousel.js`)

**Created new module with:**
- `HeroCarousel` class that manages background image transitions
- Auto-initialization on DOM ready
- Configurable options:
  - `imageInterval`: 10000ms (10 seconds) for background images
  - `ctaInterval`: 5000ms (5 seconds) for CTA text
  - `transitionDuration`: 2000ms (2 seconds) fade effect
  - `images`: Array of Pexels image URLs

**Features:**
- **Independent timers** for images and CTA content
- Automatic cycling through images (every 10 seconds)
- **Dynamic CTA content switching** (every 5 seconds) - alternates between two call-to-action messages
- Smooth CSS-based dissolve transitions
- Pause on hover functionality (pauses both timers)
- Clean lifecycle management (init/destroy)

**Image Sources:**
1. **Primary**: Admin-approved images from database (`HeroImage.approved_for_carousel`)
2. **Fallback**: 10 hardcoded Pexels images (used if no approved images exist)

**Fallback Images (Pexels - Landscape, 3+ People):**
1. `https://images.pexels.com/photos/1581384/pexels-photo-1581384.jpeg?auto=compress&cs=tinysrgb&w=1920`
2. `https://images.pexels.com/photos/696218/pexels-photo-696218.jpeg?auto=compress&cs=tinysrgb&w=1920`
3. `https://images.pexels.com/photos/941861/pexels-photo-941861.jpeg?auto=compress&cs=tinysrgb&w=1920`
4. `https://images.pexels.com/photos/67468/pexels-photo-67468.jpeg?auto=compress&cs=tinysrgb&w=1920`
5. `https://images.pexels.com/photos/3201921/pexels-photo-3201921.jpeg?auto=compress&cs=tinysrgb&w=1920`
6. `https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg?auto=compress&cs=tinysrgb&w=1920`
7. `https://images.pexels.com/photos/1307698/pexels-photo-1307698.jpeg?auto=compress&cs=tinysrgb&w=1920`
8. `https://images.pexels.com/photos/2788792/pexels-photo-2788792.jpeg?auto=compress&cs=tinysrgb&w=1920`
9. `https://images.pexels.com/photos/1126728/pexels-photo-1126728.jpeg?auto=compress&cs=tinysrgb&w=1920`
10. `https://images.pexels.com/photos/2788799/pexels-photo-2788799.jpeg?auto=compress&cs=tinysrgb&w=1920`

**Randomization:** Images are shuffled on each page load using Fisher-Yates algorithm, so visitors see a different sequence each time.

### 3. Application Integration (`app/javascript/application.js`)

**Added import:**
```javascript
// Import hero carousel for homepage
import './modules/hero_carousel.js'
```

### 4. View Updates (`app/views/home/index.html.erb`)

**Simplified hero carousel markup:**
- Removed Bootstrap carousel structure (`carousel-inner`, `carousel-item`)
- Removed static placeholder images
- Removed container wrapper for absolute positioning
- CTA overlay positioned at bottom of images
- Background images now dynamically inserted by JavaScript

**Before:**
```erb
<div id="myCarousel" class="carousel hero-carousel" data-bs-ride="carousel">
  <div class="carousel-inner">
    <div class="carousel-item active">...</div>
    <div class="carousel-item">...</div>
  </div>
</div>
```

**After:**
```erb
<div class="hero-carousel" 
     data-cta1-title="<%=t('.ctaTitle1')%>" 
     data-cta1-body="<%=t('.ctaBody1')%>"
     data-cta2-title="<%=t('.ctaTitle2')%>" 
     data-cta2-body="<%=t('.ctaBody2')%>">
  <!-- Background images will be dynamically inserted by JavaScript -->
  <div class="hero-caption text-start">
    <h1 data-cta-title><%=t(".ctaTitle1")%></h1>
    <p data-cta-body><strong><%=t(".ctaBody1")%></strong></p>
    <p><%= link_to t(".signUp"), new_user_registration_path, class: "btn btn-danger" %></p>
  </div>
</div>
```

**Key Changes:**
- Added `data-cta1-*` and `data-cta2-*` attributes to pass translated content to JavaScript
- Added `data-cta-title` and `data-cta-body` attributes to identify elements for dynamic updates
- JavaScript reads translations and cycles between them

### 5. CSS Positioning Updates

**CTA Overlay Positioning:**
- Changed from `position: relative` to `position: absolute`
- Anchored to `bottom: 40px` (desktop) and `bottom: 20px` (mobile)
- Maintains left/right padding of 5% (desktop) and 10px (mobile)
- Ensures CTA is always visible at the bottom of the hero section

## How It Works

1. **Page Load**: JavaScript detects `.hero-carousel` element
2. **CTA Content Loading**: Reads `data-cta1-*` and `data-cta2-*` attributes from container
3. **Randomization**: Image array is shuffled using Fisher-Yates algorithm
4. **Initialization**: Creates multiple `.hero-background` divs (one per randomized image)
5. **First Image**: First background div gets `.active` class (opacity: 1)
6. **Independent Timers Start**:
   - **Image Timer**: Fires every 10 seconds
   - **CTA Timer**: Fires every 5 seconds
7. **Image Transition** (every 10 seconds):
   - Current image loses `.active` class → fades to opacity: 0
   - Next image gains `.active` class → fades to opacity: 1
   - CSS handles the smooth 2-second background transition
8. **CTA Transition** (every 5 seconds):
   - **CTA text fades out** (opacity: 0) over 0.5s
   - **CTA content updates** (title and body text change)
   - **CTA text fades in** (opacity: 1) over 0.5s
   - Alternates between two CTA messages independently of images
9. **Loop**: Both timers cycle independently through their content
10. **CTA Overlay**: Positioned absolutely at the bottom, always visible over images
11. **Pause on Hover**: Both timers pause when hovering over carousel

## Customization

To change timing or images, edit `app/javascript/modules/hero_carousel.js`:

```javascript
const heroCarousel = new HeroCarousel('.hero-carousel', {
  imageInterval: 10000, // Background image changes (ms)
  ctaInterval: 5000, // CTA text changes (ms)
  transitionDuration: 2000, // Fade duration (ms)
  images: [
    'your-image-url-1.jpg',
    'your-image-url-2.jpg',
    // Add more images...
  ]
});
```

**Timing Recommendations:**
- **CTA Interval**: 5-10 seconds (keeps content fresh without being jarring)
- **Image Interval**: 10-15 seconds (allows time to appreciate each image)
- **Transition Duration**: 1-3 seconds (smooth but not too slow)

**Current Configuration:**
- CTA changes every **5 seconds**
- Images change every **10 seconds**
- Transitions take **2 seconds**

## Browser Compatibility

- Modern browsers with CSS transition support
- Graceful degradation: First image shows if JavaScript disabled
- No external dependencies beyond existing Bootstrap/jQuery

## Performance

- Images loaded once on page load
- Pure CSS transitions (GPU accelerated)
- No DOM manipulation during transitions
- Minimal JavaScript overhead

## Testing

1. Visit homepage (logged out)
2. Observe hero section background
3. Wait 30 seconds to see first transition
4. Hover over hero section to pause carousel
5. Move mouse away to resume

## Future Enhancements

- Lazy loading for images
- Preload next image before transition
- Add loading indicators
- Responsive image sources (srcset)
- Admin interface to manage carousel images
