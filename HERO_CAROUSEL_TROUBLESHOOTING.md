# Hero Carousel Troubleshooting Guide

## Issue: Background images not changing and CTA not switching

### Recent Fixes Applied

1. **Added importmap configuration** for modules directory
2. **Added console logging** for debugging
3. **Added multiple initialization methods** (DOMContentLoaded, turbo:load)
4. **Added robust error handling**

### Steps to Fix

#### 1. Restart Rails Server
```bash
# Stop the current server (Ctrl+C)
# Then restart
bin/rails server
```

#### 2. Clear Browser Cache
- Hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows/Linux)
- Or open in incognito/private window

#### 3. Check Browser Console
Open browser console (F12 or Right-click → Inspect → Console) and look for:

**Expected console output:**
```
[HeroCarousel] Initializing...
[HeroCarousel] Container found, creating carousel
[HeroCarousel] Creating background layers...
[HeroCarousel] Starting carousel with 10 images
[HeroCarousel] Init complete. CTA elements: {title: h1, body: p}
[HeroCarousel] Carousel initialized successfully
```

**After 30 seconds, you should see:**
```
[HeroCarousel] Transitioning from image 0 to next image
[HeroCarousel] Now showing image 1
```

#### 4. Check for JavaScript Errors
Look for any red error messages in the console, especially:
- Module loading errors
- Import errors
- "Cannot read property" errors

### Common Issues and Solutions

#### Issue 1: Module Not Found
**Error:** `Failed to resolve module specifier "modules/hero_carousel"`

**Solution:**
```bash
# Restart Rails server to reload importmap
bin/rails server
```

#### Issue 2: Container Not Found
**Console shows:** `[HeroCarousel] Container not found, skipping initialization`

**Solution:** Check that you're on the homepage while logged out. The carousel only appears for non-logged-in users.

#### Issue 3: Images Not Loading
**Symptoms:** Background stays white, no images visible

**Solution:** Check network tab in browser dev tools:
1. Open Dev Tools (F12)
2. Go to Network tab
3. Refresh page
4. Look for failed image requests from pexels.com
5. If blocked, check firewall/ad blocker

#### Issue 4: CTA Elements Not Found
**Console shows:** `CTA elements: {title: null, body: null}`

**Solution:** Check that data attributes are present in HTML:
```html
<h1 data-cta-title>...</h1>
<p data-cta-body>...</p>
```

### Manual Testing Steps

#### Test 1: Verify HTML Structure
1. Open browser dev tools (F12)
2. Go to Elements/Inspector tab
3. Find `.hero-carousel` element
4. Verify it has data attributes:
   - `data-cta1-title`
   - `data-cta1-body`
   - `data-cta2-title`
   - `data-cta2-body`
5. Verify child elements have:
   - `<h1 data-cta-title>`
   - `<p data-cta-body>`

#### Test 2: Verify Background Layers Created
1. In Elements tab, expand `.hero-carousel`
2. You should see 10 `<div class="hero-background">` elements
3. First one should have class `hero-background active`
4. Each should have inline style: `background-image: url(...)`

#### Test 3: Force Immediate Transition
Open browser console and run:
```javascript
// This will trigger an immediate transition for testing
const carousel = document.querySelector('.hero-carousel');
if (carousel) {
  const event = new Event('mouseenter');
  carousel.dispatchEvent(event);
  setTimeout(() => {
    const event2 = new Event('mouseleave');
    carousel.dispatchEvent(event2);
  }, 100);
}
```

### Quick Fix: Reduce Wait Time for Testing

Temporarily change interval to 5 seconds for faster testing:

**Edit:** `app/javascript/modules/hero_carousel.js`

```javascript
// Change this line:
interval: 30000, // 30 seconds

// To this:
interval: 5000, // 5 seconds (for testing only)
```

Then restart server and wait just 5 seconds to see transitions.

**Remember to change back to 30000 for production!**

### Files to Check

1. **JavaScript Module:**
   - `/app/javascript/modules/hero_carousel.js`
   - Should have console.log statements

2. **Importmap Configuration:**
   - `/config/importmap.rb`
   - Should have: `pin_all_from 'app/javascript/modules', under: 'modules'`

3. **Application JavaScript:**
   - `/app/javascript/application.js`
   - Should have: `import './modules/hero_carousel.js'`

4. **View File:**
   - `/app/views/home/index.html.erb`
   - Should have data attributes on `.hero-carousel`

5. **CSS File:**
   - `/app/assets/stylesheets/pages/_home.scss`
   - Should have `.hero-background` and `.hero-caption` styles

### Still Not Working?

If none of the above works, try this nuclear option:

```bash
# 1. Stop Rails server
# 2. Clear all caches
bin/rails tmp:clear

# 3. Rebuild assets
yarn build:css

# 4. Restart server
bin/rails server

# 5. Hard refresh browser (Cmd+Shift+R)
```

### Getting Help

If still not working, provide:
1. Full browser console output (copy/paste all messages)
2. Any red error messages
3. Screenshot of Elements tab showing `.hero-carousel` structure
4. Rails version: `bin/rails --version`
5. Ruby version: `ruby --version`

### Success Indicators

✅ Console shows initialization messages
✅ 10 background divs created in DOM
✅ First background has `active` class
✅ After 30 seconds, console shows transition message
✅ Background image visibly changes
✅ CTA text fades and changes
✅ No errors in console

### Performance Notes

- **First load:** May take 1-2 seconds to load all images
- **Transitions:** Should be smooth 2-second fades
- **Memory:** ~10MB for all images (normal)
- **CPU:** Minimal, CSS handles transitions
