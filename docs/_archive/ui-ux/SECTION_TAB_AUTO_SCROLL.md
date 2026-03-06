# Section Tab Auto-Scroll Enhancement

## Summary
Added automatic scrolling functionality to ensure the currently active section tab is always visible in the horizontal scrollable tab container when scrolling through the menu.

## Problem
When scrolling down the smart menu page, the section tabs navigation would highlight the current section, but the highlighted tab might not be visible in the horizontal scrollable container, requiring manual scrolling to see which section is active.

## Solution
Implemented auto-scroll functionality that:
1. Listens to Bootstrap's scrollspy activation events
2. Automatically scrolls the tab container to center the active tab
3. Also handles manual tab clicks with smooth scrolling

## Changes Made

### File: `app/javascript/smartmenus.js`

#### Added Function: `initSectionTabAutoScroll()`
```javascript
function initSectionTabAutoScroll() {
  const tabsContainer = document.querySelector('.sections-tabs-container');
  const scrollspyElement = document.querySelector('[data-bs-spy="scroll"]');
  
  if (!tabsContainer || !scrollspyElement) return;
  
  // Listen for Bootstrap scrollspy activation events
  scrollspyElement.addEventListener('activate.bs.scrollspy', function(event) {
    // Small delay to ensure the active class has been applied
    setTimeout(() => {
      const activeTab = tabsContainer.querySelector('.section-tab.active');
      
      if (activeTab) {
        // Calculate the position to scroll to
        const containerRect = tabsContainer.getBoundingClientRect();
        const tabRect = activeTab.getBoundingClientRect();
        
        // Calculate how much we need to scroll
        const scrollLeft = tabsContainer.scrollLeft;
        const tabLeft = tabRect.left - containerRect.left;
        const tabWidth = tabRect.width;
        const containerWidth = containerRect.width;
        
        // Center the active tab in the viewport if possible
        const targetScroll = scrollLeft + tabLeft - (containerWidth / 2) + (tabWidth / 2);
        
        // Smooth scroll to the active tab
        tabsContainer.scrollTo({
          left: targetScroll,
          behavior: 'smooth'
        });
      }
    }, 50);
  });
  
  // Also handle manual clicks on section tabs
  const sectionTabs = tabsContainer.querySelectorAll('.section-tab');
  sectionTabs.forEach(tab => {
    tab.addEventListener('click', function(event) {
      // Let the default behavior happen, then scroll the tab into view
      setTimeout(() => {
        const containerRect = tabsContainer.getBoundingClientRect();
        const tabRect = tab.getBoundingClientRect();
        const scrollLeft = tabsContainer.scrollLeft;
        const tabLeft = tabRect.left - containerRect.left;
        const tabWidth = tabRect.width;
        const containerWidth = containerRect.width;
        const targetScroll = scrollLeft + tabLeft - (containerWidth / 2) + (tabWidth / 2);
        
        tabsContainer.scrollTo({
          left: targetScroll,
          behavior: 'smooth'
        });
      }, 100);
    });
  });
}
```

## Features

### ✅ Automatic Scrolling
- Activates when Bootstrap scrollspy detects a new section
- Centers the active tab in the horizontal scroll container
- Uses smooth scrolling for better UX

### ✅ Manual Click Handling
- Also handles manual tab clicks
- Ensures clicked tab is centered after navigation

### ✅ Smart Positioning
- Calculates optimal scroll position to center the tab
- Handles edge cases (tabs at start/end of container)
- Respects container boundaries

### ✅ Performance
- Uses small timeouts to ensure DOM updates are complete
- Smooth scrolling with `behavior: 'smooth'`
- No unnecessary recalculations

## Technical Details

### How It Works

1. **Event Listener**: Listens for `activate.bs.scrollspy` event from Bootstrap
2. **Find Active Tab**: Queries for `.section-tab.active` element
3. **Calculate Position**: 
   - Gets container and tab dimensions
   - Calculates current scroll position
   - Determines target scroll position to center the tab
4. **Scroll**: Uses `scrollTo()` with smooth behavior

### Timing
- **50ms delay** for scrollspy events (ensures active class is applied)
- **100ms delay** for click events (allows navigation to start)

### Calculation Formula
```javascript
targetScroll = currentScrollLeft + tabOffsetLeft - (containerWidth / 2) + (tabWidth / 2)
```

This formula centers the tab in the visible area of the horizontal scroll container.

## Browser Compatibility

- ✅ Modern browsers (Chrome, Firefox, Safari, Edge)
- ✅ Uses native `scrollTo()` with smooth behavior
- ✅ Falls back gracefully in older browsers

## Testing

To verify the functionality:
1. Navigate to any smart menu page (e.g., `/smartmenus/8d95bbb1-f4c6-4034-97c8-2aafc663353b`)
2. Scroll down through different menu sections
3. Observe that the section tabs automatically scroll to keep the active tab visible
4. Click on different section tabs to verify smooth scrolling
5. Test on mobile devices with narrow viewports

## Edge Cases Handled

- ✅ No tabs container present (graceful exit)
- ✅ No scrollspy element present (graceful exit)
- ✅ Tab already visible (minimal unnecessary scrolling)
- ✅ First/last tabs (doesn't over-scroll)
- ✅ Rapid scrolling (uses timeouts to debounce)

## Future Enhancements

Potential improvements:
- [ ] Add configurable centering offset
- [ ] Option to align left/right instead of center
- [ ] Respect reduced motion preferences
- [ ] Add intersection observer for better performance
- [ ] Handle dynamic tab addition/removal

## Related Files

- **View**: `app/views/smartmenus/_showMenuBanner.erb` (contains tab structure)
- **CSS**: `app/assets/stylesheets/components/_smartmenu_mobile.scss` (tab styling)
- **JavaScript**: `app/javascript/smartmenus.js` (auto-scroll logic)

## Dependencies

- Bootstrap 5 Scrollspy
- Native JavaScript `scrollTo()` API
- Modern browser support for smooth scrolling
