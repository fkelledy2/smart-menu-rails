# **🧪 Testing the New Restaurant Edit UI**

**Date:** November 2, 2025  
**Status:** Ready to Test  
**Access Method:** URL Parameter

---

## **🚀 Quick Start**

### **1. Start Your Server**
```bash
rails s
# or
bin/dev
```

### **2. Navigate to New UI**
```
http://localhost:3000/restaurants/1/edit?new_ui=true
```

**Replace `1` with your actual restaurant ID**

---

## **📍 Finding Your Restaurant ID**

### **Option A: From Restaurants Index**
1. Go to `http://localhost:3000/restaurants`
2. Look at the URL when clicking "Edit" on a restaurant
3. The number in the URL is your restaurant ID

### **Option B: From Rails Console**
```ruby
rails c
Restaurant.first.id  # Get first restaurant ID
# or
User.first.restaurants.first.id  # Get your first restaurant
```

---

## **✅ What to Test**

### **Desktop View (> 768px)**

#### **Sidebar Navigation:**
- [ ] **4 sections visible** (CORE, MENUS, TEAM, SETUP)
- [ ] **Badge counts** show correct numbers
  - Menus count (all menus)
  - Active menus count
  - Staff count
- [ ] **Active state** highlights current section
- [ ] **Hover states** work smoothly
- [ ] **Sticky positioning** - sidebar stays when scrolling

#### **Quick Actions:**
- [ ] **New Menu** button navigates correctly
- [ ] **Bulk Import** button works
- [ ] **QR Code** button accessible
- [ ] Buttons have hover effects

#### **Overview Stats:**
- [ ] Shows correct counts:
  - Total menus
  - Total items
  - Staff count
  - Active menus
- [ ] Numbers match actual data

#### **Form Functionality:**
- [ ] **Restaurant name** field editable
- [ ] **Description** textarea works
- [ ] **Currency** selector functional
- [ ] **Phone** and **Email** fields work
- [ ] **Website** field accepts URLs
- [ ] **Address** fields all work
- [ ] **Auto-save indicator** appears
  - Shows "⟳ Saving..." while saving
  - Shows "✓ Saved" after completion
  - Disappears after a few seconds

#### **Header Actions:**
- [ ] **Preview Site** button works
- [ ] **Dropdown menu** (three dots) opens
  - QR Codes option
  - Export option
  - Archive option (red text)

---

### **Mobile View (< 768px)**

#### **Navigation:**
- [ ] **Hamburger menu** button (☰) visible
- [ ] Clicking hamburger **opens sidebar from left**
- [ ] **Overlay** appears behind sidebar (dims content)
- [ ] Clicking **overlay closes sidebar**
- [ ] Sidebar has **close button (X)** in header
- [ ] Sidebar **full height** on mobile

#### **Sidebar Content:**
- [ ] All 4 sections visible
- [ ] Links are **touch-friendly** (44px+)
- [ ] Badge counts visible
- [ ] Scrollable if content exceeds screen

#### **Forms:**
- [ ] Fields stack vertically
- [ ] Inputs fill width
- [ ] Touch targets adequate
- [ ] No horizontal scroll
- [ ] Auto-save still works

---

## **🎨 Visual Checks**

### **Colors & Styling:**
- [ ] **Primary blue** for active links and actions
- [ ] **Gray sidebar** background
- [ ] **White content** area
- [ ] **Hover effects** smooth
- [ ] **Shadows** subtle on cards
- [ ] **Icons** display correctly (Bootstrap Icons)

### **Typography:**
- [ ] **Section titles** uppercase and small
- [ ] **Links** readable size
- [ ] **Form labels** clear
- [ ] **Help text** gray and smaller

### **Spacing:**
- [ ] **Consistent padding** in cards
- [ ] **Gap between** quick action buttons
- [ ] **Margins** around sections
- [ ] **No overlapping** elements

---

## **⚠️ Common Issues & Solutions**

### **Issue: Styles not loading**
**Solution:** Rebuild CSS
```bash
yarn build:css
# or restart server
```

### **Issue: Sidebar not appearing**
**Solution:** Check browser console for errors
- Open DevTools (F12)
- Look for JavaScript errors
- Check Network tab for failed CSS/JS loads

### **Issue: 404 on edit_2025 view**
**Solution:** Verify file exists
```bash
ls app/views/restaurants/edit_2025.html.erb
```

### **Issue: Auto-save not working**
**Solution:** Check Stimulus controller loaded
- Open browser console
- Look for "[Sidebar] Controller connected"
- Check for auto-save related messages

### **Issue: Mobile sidebar not opening**
**Solution:** Check Stimulus controller
- Verify `sidebar_controller.js` exists
- Check browser console for errors
- Try refreshing page

---

## **📱 Mobile Device Testing**

### **Using Chrome DevTools:**
1. **Open DevTools** - Press `F12` or `Cmd+Option+I` (Mac)
2. **Toggle Device Toolbar** - Press `Cmd+Shift+M` (Mac) or `Ctrl+Shift+M` (Windows)
3. **Select Device:**
   - iPhone 12 Pro (390 x 844)
   - iPhone SE (375 x 667)
   - Pixel 5 (393 x 851)
   - iPad Air (820 x 1180)
4. **Test Features:**
   - Hamburger menu
   - Sidebar open/close
   - Form interactions
   - Touch targets

### **Using Real Device:**
1. Find your computer's **local IP address**:
   ```bash
   # Mac/Linux
   ifconfig | grep "inet "
   
   # Windows
   ipconfig
   ```

2. Access from mobile device:
   ```
   http://YOUR_IP:3000/restaurants/1/edit?new_ui=true
   ```
   Example: `http://192.168.1.100:3000/restaurants/1/edit?new_ui=true`

3. Test on actual device:
   - Touch interactions
   - Scrolling behavior
   - Keyboard appearance
   - Form submission

---

## **🔍 Browser Testing**

### **Recommended Browsers:**
- [ ] **Chrome** (latest) - Primary development
- [ ] **Firefox** (latest) - Check compatibility
- [ ] **Safari** (latest) - Mac/iOS testing
- [ ] **Edge** (latest) - Windows testing

### **What to Check:**
- [ ] Sidebar displays correctly
- [ ] Hover states work
- [ ] Forms function properly
- [ ] Auto-save indicators appear
- [ ] Mobile menu works
- [ ] No console errors

---

## **📊 Performance Checks**

### **Page Load:**
- [ ] Initial load < 2 seconds
- [ ] No layout shift (CLS)
- [ ] Styles load immediately
- [ ] No FOUC (Flash of Unstyled Content)

### **Interactions:**
- [ ] Sidebar links respond instantly
- [ ] Hover effects smooth (no lag)
- [ ] Form typing responsive
- [ ] Auto-save doesn't block UI

### **Mobile:**
- [ ] Sidebar animation smooth (300ms)
- [ ] No jank when scrolling
- [ ] Touch responses immediate
- [ ] Overlay fade smooth

---

## **🐛 Debugging Tips**

### **Check Browser Console:**
```javascript
// Should see:
[Sidebar] Controller connected

// When typing in form:
[AutoSave] Field changed: name
[AutoSave] Saving...
[AutoSave] Saved successfully
```

### **Check Network Tab:**
- CSS files loading (application.css)
- JS files loading (application.js)
- No 404 errors
- Auto-save POST requests succeeding

### **Check Elements Tab:**
- `.sidebar-2025` element present
- `.sidebar-link.active` class on current section
- `.btn-2025` classes on buttons
- `.form-control-2025` classes on inputs

---

## **✅ Success Criteria**

### **Must Work:**
- ✅ Sidebar navigation functional
- ✅ Active states highlight correctly
- ✅ Forms auto-save
- ✅ Mobile menu opens/closes
- ✅ No console errors
- ✅ All sections accessible

### **Should Work:**
- ✅ Hover effects smooth
- ✅ Badge counts accurate
- ✅ Quick actions navigate
- ✅ Stats display correctly
- ✅ Responsive on all devices

### **Nice to Have:**
- ✅ Animations smooth
- ✅ Loading states clear
- ✅ Error handling graceful
- ✅ Keyboard navigation works

---

## **📝 Feedback Checklist**

After testing, note:

### **What Works Well:**
- [ ] Navigation clarity
- [ ] Visual design
- [ ] Form usability
- [ ] Mobile experience
- [ ] Performance

### **What Needs Improvement:**
- [ ] Confusing elements
- [ ] Missing functionality
- [ ] Performance issues
- [ ] Mobile problems
- [ ] Visual inconsistencies

### **Feature Requests:**
- [ ] Additional quick actions
- [ ] More statistics
- [ ] Keyboard shortcuts
- [ ] Drag-to-reorder sections
- [ ] Search/filter

---

## **🎯 Next Steps**

### **If Everything Works:**
1. ✅ Create additional sections (address, hours, etc.)
2. ✅ Enable for all users (remove `?new_ui=true` requirement)
3. ✅ Apply pattern to Menu edit page
4. ✅ Gather user feedback
5. ✅ Iterate based on feedback

### **If Issues Found:**
1. 🐛 Document the issue
2. 🐛 Check browser console
3. 🐛 Note browser/device
4. 🐛 Provide screenshot if possible
5. 🐛 Report for fixing

---

## **📞 Need Help?**

### **Documentation:**
- `docs/frontend/EDIT_PAGES_UX_ANALYSIS.md` - Full UX analysis
- `docs/frontend/EDIT_PAGES_MOCKUPS.md` - Visual mockups
- `docs/frontend/PHASE_1_IMPLEMENTATION.md` - Implementation details

### **Code Files:**
- `app/assets/stylesheets/components/_sidebar_2025.scss` - Styles
- `app/views/restaurants/_sidebar_2025.html.erb` - Sidebar HTML
- `app/views/restaurants/edit_2025.html.erb` - Main page
- `app/javascript/controllers/sidebar_controller.js` - Interactions

---

## **🎊 You're Ready to Test!**

**URL to access:**
```
http://localhost:3000/restaurants/YOUR_ID/edit?new_ui=true
```

**What to expect:**
- Modern sidebar navigation (left side)
- 4 grouped sections instead of 13 tabs
- Quick action buttons at top
- Overview statistics
- Auto-saving forms
- Mobile-friendly hamburger menu

**Happy testing!** 🚀

If you find any issues or have suggestions, the new UI is designed to be iterated on quickly.
