# Performance Testing Guide

## How to Test

### 1. Clear Browser Cache
```bash
# Chrome DevTools: Network tab → Disable cache
# Or use Incognito mode
```

### 2. Test Customer View
```
Visit: https://your-app.com/smartmenus/[slug]
Without being logged in
```

### 3. Check Network Tab
**Before (Expected):**
- application.js: ~1.5MB
- Total JS: ~2MB+
- TTI: 4-6s

**After (Expected):**
- smartmenu_customer.js: ~200KB
- Total JS: ~400KB
- TTI: 1.5-2s

### 4. Lighthouse Audit
```bash
# Run in Chrome DevTools
Performance → Generate report
Target: 90+ score
```

## Verification Checklist

- [ ] Customer view loads `smartmenu_customer.js` (not `application.js`)
- [ ] Staff view still loads full `application.js`
- [ ] First 3 menu images load with `fetchpriority="high"`
- [ ] Images blur-up on load (CSS transition)
- [ ] No jQuery errors in console
- [ ] ActionCable still works (order updates)
- [ ] Bottom sheet cart functions
- [ ] Menu search/filter works
- [ ] Layout toggle work- [ ] Layout toggle work- [ ]  occur:
```bash
git revert HEAD~2  # Revert last 2 commits
```

Or disable customer bundle:
```ruby
# app/helpers/javascript_helper.rb
def smartmenu_javascript_tags
  javascript_importmap_tags  # Always use full bundle
end
```
