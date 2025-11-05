# Manual Test: Mobile Sidebar Navigation

## Purpose
Verify that the mobile sidebar toggle works correctly without immediately closing.

## Prerequisites
- Rails server running on `http://localhost:3000`
- Logged in as a user with restaurant access
- Browser dev tools open to mobile device mode

## Test Setup

### 1. Open Browser Dev Tools
- **Chrome**: F12 or Cmd+Option+I (Mac)
- Enable Device Toolbar: Click the device icon or press Cmd+Shift+M (Mac)

### 2. Select Mobile Device
- Choose "iPhone SE" or "iPhone 12 Pro" from device dropdown
- Or set custom dimensions: 375px width × 667px height

### 3. Navigate to Restaurant Edit Page
```
http://localhost:3000/restaurants/1/edit?section=details
```

---

## Test Cases

### ✅ Test 1: Sidebar Opens and Stays Open

**Steps:**
1. Verify hamburger menu button (☰) is visible in top right
2. Click the hamburger menu button once
3. Wait 500ms

**Expected Result:**
- ✅ Sidebar slides in from the left
- ✅ Dark overlay appears behind sidebar
- ✅ Sidebar remains open (does not immediately close)
- ✅ Console shows: `[Sidebar] Added 'open' class to sidebar`
- ✅ Console does NOT show: `[Sidebar] Closing sidebar` immediately after

**Actual Result:** _____________

---

### ✅ Test 2: Close Button Works

**Steps:**
1. With sidebar open from Test 1
2. Click the X button in sidebar header
3. Wait 500ms

**Expected Result:**
- ✅ Sidebar slides out to the left
- ✅ Overlay fades out
- ✅ Console shows: `[Sidebar] Closing sidebar`

**Actual Result:** _____________

---

### ✅ Test 3: Overlay Click Closes Sidebar

**Steps:**
1. Click hamburger menu to open sidebar
2. Click on the dark overlay (not the sidebar itself)
3. Wait 500ms

**Expected Result:**
- ✅ Sidebar closes
- ✅ Overlay disappears
- ✅ Page is interactive again

**Actual Result:** _____________

---

### ✅ Test 4: Rapid Clicks Don't Cause Flicker

**Steps:**
1. Click hamburger menu button 5 times rapidly
2. Observe behavior

**Expected Result:**
- ✅ Sidebar opens after first click
- ✅ Subsequent clicks are ignored (debounced)
- ✅ Console shows: `[Sidebar] Ignoring rapid toggle (Xms since last toggle)`
- ✅ Sidebar does NOT flicker open/close/open/close

**Actual Result:** _____________

---

### ✅ Test 5: Navigation Links Work

**Steps:**
1. Open sidebar
2. Click on "Address" link in sidebar
3. Wait 1 second

**Expected Result:**
- ✅ Content area updates to Address section
- ✅ URL changes to `?section=address`
- ✅ Sidebar closes automatically after clicking link (on mobile)
- ✅ "Address" link is highlighted as active

**Actual Result:** _____________

---

### ✅ Test 6: Body Scroll Prevention

**Steps:**
1. Open sidebar
2. Try to scroll the page behind the sidebar
3. Close sidebar
4. Try to scroll again

**Expected Result:**
- ✅ While sidebar is open: page does NOT scroll
- ✅ Console shows: `document.body.style.overflow = 'hidden'`
- ✅ After sidebar closes: page scrolls normally
- ✅ Console shows: `document.body.style.overflow = ''`

**Actual Result:** _____________

---

### ✅ Test 7: Desktop Resize Closes Sidebar

**Steps:**
1. Open sidebar on mobile
2. Resize browser to desktop width (>768px)
3. Observe behavior

**Expected Result:**
- ✅ Sidebar automatically closes
- ✅ Sidebar is visible as permanent sidebar on desktop
- ✅ Hamburger menu button is hidden
- ✅ No overlay visible

**Actual Result:** _____________

---

### ✅ Test 8: Turbo Navigation Maintains State

**Steps:**
1. Click a sidebar link to navigate
2. Wait for Turbo Frame to load
3. Click hamburger menu again

**Expected Result:**
- ✅ Sidebar opens without errors
- ✅ No JavaScript console errors
- ✅ Toggle still works after navigation
- ✅ No duplicate event listeners (check console for multiple `[Sidebar] Controller connected` messages)

**Actual Result:** _____________

---

## Console Log Verification

### Good Pattern (Sidebar Opens and Stays Open):
```
[Sidebar] Toggle called
[Sidebar] Has sidebar target? true
[Sidebar] Sidebar element: <aside class="sidebar-2025"...
[Sidebar] Opening sidebar
[Sidebar] Open - Sidebar element: <aside...
[Sidebar] Open - Overlay element: <div...
[Sidebar] Added 'open' class to sidebar
[Sidebar] Added 'active' class to overlay
```

### Bad Pattern (Sidebar Immediately Closes):
```
[Sidebar] Toggle called
[Sidebar] Opening sidebar
[Sidebar] Added 'open' class to sidebar
[Sidebar] Toggle called          ← SECOND TOGGLE (BAD!)
[Sidebar] Closing sidebar        ← IMMEDIATELY CLOSES (BAD!)
```

---

## Debug Steps if Tests Fail

### If sidebar doesn't appear:
1. Check console for JavaScript errors
2. Verify z-index: `z-index: 1050` on `.sidebar-2025`
3. Inspect element: should have `left: 0` when open
4. Check CSS: `transition: left 0.3s ease-in-out`

### If sidebar immediately closes:
1. Check console for multiple "Toggle called" messages
2. Look for "Ignoring rapid toggle" messages
3. If missing, check that `stopImmediatePropagation()` is being called
4. Verify only one Stimulus controller is attached

### If debounce doesn't work:
1. Check timestamp log messages
2. Should see: `Ignoring rapid toggle (50ms since last toggle)`
3. Verify `Date.now()` is working
4. Check browser console time stamps

---

## Success Criteria

All 8 tests must pass:
- [ ] Test 1: Sidebar opens and stays open
- [ ] Test 2: Close button works
- [ ] Test 3: Overlay click closes sidebar
- [ ] Test 4: Rapid clicks don't cause flicker
- [ ] Test 5: Navigation links work
- [ ] Test 6: Body scroll prevention
- [ ] Test 7: Desktop resize closes sidebar
- [ ] Test 8: Turbo navigation maintains state

---

## Additional Checks

### Performance:
- Sidebar animation should be smooth (60fps)
- No jank or stuttering during open/close
- Overlay fade should be smooth

### Accessibility:
- Hamburger button has `aria-label="Toggle navigation"`
- Close button has `aria-label="Close menu"`
- Keyboard users can tab through sidebar links
- Escape key closes sidebar (if implemented)

### Cross-browser:
- Test on Safari iOS
- Test on Chrome Android
- Test on Firefox Mobile

---

## Related Files
- **Controller**: `app/javascript/controllers/sidebar_controller.js`
- **View**: `app/views/restaurants/edit_2025.html.erb`
- **Partial**: `app/views/restaurants/_sidebar_2025.html.erb`
- **Styles**: `app/assets/stylesheets/components/_sidebar_2025.scss`
- **System Test**: `test/system/sidebar_mobile_test.rb`
- **JS Test**: `test/javascript/sidebar_controller.test.js`
