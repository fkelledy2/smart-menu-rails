# Smart Menu - Product Requirements Document
# Part 3: User Journeys & Workflows

**Version:** 1.0  
**Last Updated:** October 26, 2025

---

## Table of Contents

1. [Journey 1: Restaurant Owner Onboarding](#journey-1-restaurant-owner-onboarding)
2. [Journey 2: Importing Existing Menu via OCR](#journey-2-importing-existing-menu-via-ocr)
3. [Journey 3: Customer Ordering Experience](#journey-3-customer-ordering-experience)
4. [Journey 4: Kitchen Staff Managing Orders](#journey-4-kitchen-staff-managing-orders)
5. [Journey 5: Restaurant Owner Viewing Analytics](#journey-5-restaurant-owner-viewing-analytics)
6. [Journey 6: Managing Multi-Location Restaurant](#journey-6-managing-multi-location-restaurant)

---

## Journey 1: Restaurant Owner Onboarding

**Persona:** Restaurant Owner (Primary)  
**Goal:** Set up restaurant and deploy first smart menu  
**Time:** 5-10 minutes  
**Success Criteria:** Complete onboarding, generate QR code, place test order

### Flow Diagram

```
Start → Registration → Onboarding Wizard → Dashboard → QR Deployment → Success
```

### Detailed Steps

#### 1. Registration (2 minutes)

**Actions:**
1. Visit homepage at `https://smartmenu.com`
2. Click "Sign Up" button in navigation
3. Enter email address
4. Enter password (minimum 8 characters)
5. Click "Create Account"
6. Check email for verification link
7. Click verification link
8. Account activated

**System Actions:**
- Create user record in database
- Send verification email via ActionMailer
- Generate verification token
- Create onboarding session (status: started)

**Success State:**
- User account created and verified
- Redirected to onboarding wizard Step 1

**Error Handling:**
- Email already exists → Show error, suggest login
- Invalid email format → Show inline validation error
- Weak password → Show password requirements
- Email not received → Provide resend link

---

#### 2. Onboarding Wizard (3-5 minutes)

**Step 1: Account Details**

**Actions:**
1. Enter full name
2. Click "Next"

**System Actions:**
- Validate name is present
- Update user record with name
- Update onboarding session status to `account_created`
- Track analytics event: `onboarding_step_completed` (step 1)

**UI Elements:**
- Progress bar showing 20%
- Form with name field
- "Next" button
- Back button (disabled on first step)

---

**Step 2: Restaurant Details**

**Actions:**
1. Enter restaurant name (e.g., "Bella Italia")
2. Select restaurant type from dropdown (e.g., "Fine Dining")
3. Select cuisine type from dropdown (e.g., "Italian")
4. Enter location/address (e.g., "123 Main St, New York, NY")
5. Enter phone number (optional)
6. Click "Next"

**System Actions:**
- Validate required fields (name, type, cuisine)
- Save data to onboarding session wizard_data
- Update status to `restaurant_details`
- Track analytics event: `onboarding_step_completed` (step 2)

**UI Elements:**
- Progress bar showing 40%
- Form with 5 fields
- Dropdown selectors with search
- "Next" and "Back" buttons

---

**Step 3: Plan Selection**

**Actions:**
1. Review available plans (Starter, Pro, Business, Enterprise)
2. Compare features and pricing
3. Select plan (e.g., "Starter - $29/month")
4. Click "Next"

**System Actions:**
- Validate plan selection
- Update user's plan association
- Save selected_plan_id to onboarding session
- Update status to `plan_selected`
- Track analytics events:
  - `onboarding_step_completed` (step 3)
  - `plan_selected` with plan details

**UI Elements:**
- Progress bar showing 60%
- Plan cards with features and pricing
- "Most Popular" badge on recommended plan
- "Select Plan" buttons
- "Next" and "Back" buttons

---

**Step 4: Menu Creation**

**Actions:**
1. Enter menu name (e.g., "Dinner Menu")
2. Add first menu item:
   - Name: "Margherita Pizza"
   - Price: "12.99"
   - Description: "Classic tomato and mozzarella" (optional)
3. Click "Add Another Item" to add more items
4. Add 2-3 more items
5. Click "Complete Setup"

**System Actions:**
- Validate menu name and at least one item
- Save menu data to onboarding session
- Update status to `menu_created`
- Track analytics event: `onboarding_step_completed` (step 4)
- Enqueue `RestaurantOnboardingJob` for background processing

**UI Elements:**
- Progress bar showing 80%
- Menu name field
- Dynamic item list with add/remove buttons
- Item fields (name, price, description)
- "Add Another Item" button
- "Complete Setup" button
- "Back" button

---

**Step 5: Completion**

**Display:**
1. Success message: "Your restaurant is being set up!"
2. Loading indicator
3. Preview of QR code (once generated)
4. Next steps guidance:
   - Download QR code
   - Print and place on tables
   - Test by scanning
   - Explore dashboard

**System Actions (Background Job):**
- Create restaurant record
- Create menu record
- Create menu sections (if provided)
- Create menu items
- Set default settings (currency, service charge, tax)
- Create owner employee record
- Generate smart menus for each table
- Generate QR codes
- Update onboarding session status to `completed`
- Track analytics event: `onboarding_completed`

**UI Elements:**
- Progress bar showing 100%
- Success checkmark
- QR code preview
- "Go to Dashboard" button
- "Download QR Code" button

---

#### 3. Dashboard Access (1 minute)

**Actions:**
1. Click "Go to Dashboard"
2. View restaurant overview
3. See generated smart menu
4. Click "Download QR Code"
5. Save QR code image

**System Actions:**
- Redirect to dashboard (root_path)
- Load restaurant data
- Display smart menus
- Generate QR code download

**Dashboard Elements:**
- Restaurant name and details
- Menu list
- Smart menu links
- QR code download buttons
- Quick actions (Add Menu, Add Table, View Orders)

---

#### 4. QR Code Deployment (2-5 minutes)

**Actions:**
1. Print QR code on table tents or stickers
2. Place QR codes on restaurant tables
3. Test by scanning with mobile device
4. Verify smart menu loads correctly

**System Actions:**
- QR code redirects to smart menu URL
- Smart menu loads in mobile browser
- Session created for test user
- Menu displayed with items

**Success Indicators:**
- QR code scans successfully
- Menu loads in < 2 seconds
- All items visible
- Prices displayed correctly

---

### Success Metrics

- **Completion Rate:** % of users who complete all 5 steps
- **Time to Complete:** Average time from registration to completion
- **Drop-off Points:** Which steps have highest abandonment
- **First Order Time:** Time from completion to first real order
- **QR Code Downloads:** % of users who download QR codes

### Pain Points & Solutions

**Pain Point:** User doesn't receive verification email
- **Solution:** Provide "Resend Email" button, check spam folder instructions

**Pain Point:** User unsure which plan to select
- **Solution:** Highlight "Most Popular" plan, provide feature comparison table

**Pain Point:** User wants to skip menu creation
- **Solution:** Require at least one item, but allow quick entry with minimal fields

**Pain Point:** Background job takes too long
- **Solution:** Show progress indicator, allow user to navigate to dashboard while processing

---

## Journey 2: Importing Existing Menu via OCR

**Persona:** Restaurant Owner  
**Goal:** Digitize existing PDF menu  
**Time:** 5-10 minutes (depending on PDF size)  
**Success Criteria:** Menu imported with 90%+ accuracy, minimal manual editing

### Flow Diagram

```
Start → Upload PDF → Processing → Review & Edit → Import → Success
```

### Detailed Steps

#### 1. Navigate to OCR Import (30 seconds)

**Actions:**
1. Log in to dashboard
2. Navigate to restaurant page
3. Click "Import Menu from PDF" button

**System Actions:**
- Authenticate user
- Load restaurant data
- Display OCR import interface

---

#### 2. Upload PDF (1 minute)

**Actions:**
1. Click "Choose File" or drag-and-drop PDF
2. Select PDF file from computer (e.g., "menu.pdf")
3. Click "Upload and Process"

**System Actions:**
- Validate file type (PDF only)
- Validate file size (< 10MB)
- Create OcrMenuImport record
- Attach PDF file via Active Storage
- Set status to `pending`
- Enqueue `PdfMenuExtractionJob`
- Display processing screen

**UI Elements:**
- File upload area (drag-and-drop or browse)
- File size limit indicator
- "Upload and Process" button
- Cancel button

---

#### 3. Processing (2-5 minutes)

**System Actions:**
1. **Extract Text:**
   - Check if PDF has selectable text
   - If yes: Use PDF::Reader for direct extraction
   - If no: Convert pages to images, use Google Cloud Vision OCR
   - Update progress: processed_pages / total_pages

2. **Parse with AI:**
   - Send extracted text to OpenAI ChatGPT
   - Request structured JSON output
   - Parse sections and items
   - Extract prices, descriptions, allergens

3. **Save Results:**
   - Create OcrMenuSection records
   - Create OcrMenuItem records
   - Set is_confirmed to false (pending review)
   - Update status to `completed`

**UI Elements:**
- Progress bar showing page processing
- Status messages:
  - "Extracting text from page 1 of 5..."
  - "Analyzing menu structure with AI..."
  - "Saving menu data..."
- Estimated time remaining
- Cancel button (stops processing)

---

#### 4. Review & Edit (2-5 minutes)

**Display:**
- List of extracted sections (e.g., "Appetizers", "Main Courses", "Desserts")
- List of items per section with details:
  - Name
  - Description
  - Price
  - Allergens
  - Dietary flags
- Confirmation checkboxes
- Edit buttons
- Reorder controls

**Actions:**
1. Review extracted data for accuracy
2. Edit item names if needed (inline editing)
3. Correct prices if misread
4. Add missing descriptions
5. Adjust allergen tags
6. Reorder sections (drag-and-drop)
7. Reorder items within sections
8. Confirm individual items or bulk confirm
9. Click "Import to Menu"

**System Actions:**
- Save edits to OcrMenuItem and OcrMenuSection records
- Update is_confirmed flag when confirmed
- Track confirmation status

**UI Elements:**
- Section cards (collapsible)
- Item rows with inline editing
- Confirmation checkboxes
- Edit icons
- Drag handles for reordering
- "Confirm All" button
- "Import to Menu" button
- "Cancel" button

---

#### 5. Import to Menu (30 seconds)

**Actions:**
1. Select target menu from dropdown (or create new)
2. Click "Import"
3. Confirm import action

**System Actions:**
- Run `ImportToMenu` service
- Create or update Menu record
- Create or update Menusection records
- Create or update Menuitem records
- Link allergens, ingredients, sizes
- Set dietary flags
- Preserve sequence numbers
- Track statistics (created vs updated)
- Update OcrMenuImport status

**UI Elements:**
- Menu selection dropdown
- "Create New Menu" option
- Import confirmation dialog
- Progress indicator
- Success message

---

#### 6. Finalize (1 minute)

**Actions:**
1. Review imported menu in menu editor
2. Make final adjustments if needed
3. Publish menu (set status to active)
4. Generate/update smart menu QR codes

**System Actions:**
- Load menu with all items
- Generate smart menus if not exists
- Update QR codes
- Notify user of completion

**Success Indicators:**
- All sections imported
- All items imported
- Prices correct
- Descriptions preserved
- Menu ready for deployment

---

### Success Metrics

- **Processing Time:** Average time to process PDF
- **Accuracy Rate:** % of items correctly extracted
- **Edit Rate:** % of items requiring manual editing
- **Completion Rate:** % of imports that complete successfully
- **Error Rate:** % of imports that fail

### Pain Points & Solutions

**Pain Point:** PDF processing fails
- **Solution:** Provide clear error message, suggest manual entry, offer support

**Pain Point:** AI misreads prices
- **Solution:** Highlight prices for review, provide easy inline editing

**Pain Point:** Sections not detected correctly
- **Solution:** Allow manual section creation, drag-and-drop reorganization

**Pain Point:** Too many items to review
- **Solution:** Provide bulk confirmation, filter by confirmed/unconfirmed

---

## Journey 3: Customer Ordering Experience

**Persona:** Restaurant Customer  
**Goal:** Browse menu, place order, track status, pay bill  
**Time:** 5-15 minutes  
**Success Criteria:** Order placed successfully, food delivered, payment completed

### Flow Diagram

```
Scan QR → Browse Menu → Apply Filters → Add Items → Submit Order → Track Status → Request Bill → Pay → Complete
```

### Detailed Steps

#### 1. Scan QR Code (10 seconds)

**Actions:**
1. Customer sits at table
2. Opens camera app on phone
3. Scans QR code on table tent
4. Taps notification to open link

**System Actions:**
- QR code contains smart menu URL: `/smartmenus/{slug}`
- Browser opens smart menu
- Session created with unique session ID
- Order participant created (role: customer)
- Menu loaded with associations

**Success State:**
- Smart menu loads in < 2 seconds
- Menu displayed with sections and items
- Language auto-detected or defaulted

---

#### 2. Browse Menu (2-5 minutes)

**Actions:**
1. Scroll through menu sections
2. View item details (tap to expand)
3. View item images
4. Check prices
5. Read descriptions and allergen info

**UI Elements:**
- Restaurant name and logo
- Section navigation (sticky)
- Item cards with:
  - Image (if available)
  - Name
  - Description
  - Price
  - Allergen icons
  - "Add to Order" button
- Search bar
- Filter button
- Language selector
- Cart icon with item count

---

#### 3. Apply Filters (Optional, 30 seconds)

**Actions:**
1. Tap filter button
2. Select language (e.g., Italian)
3. Select dietary filters (e.g., Vegetarian, Gluten-Free)
4. Select allergen filters (e.g., exclude Dairy)
5. Tap "Apply Filters"

**System Actions:**
- Update participant preferred locale
- Filter menu items by dietary flags
- Hide items with selected allergens
- Update UI instantly
- Save filters to session

**UI Elements:**
- Filter modal
- Language dropdown with flags
- Dietary checkboxes
- Allergen checkboxes
- "Apply" and "Clear" buttons
- Active filter badges

---

#### 4. Add Items to Order (1-3 minutes)

**Actions:**
1. Find desired item (e.g., "Margherita Pizza")
2. Tap "Add to Order"
3. Select size if applicable (S, M, L)
4. Add special instructions (optional)
5. Tap "Add"
6. Repeat for additional items
7. View cart summary

**System Actions:**
- Create or find open order for table
- Create order item record
- Link to order participant
- Calculate order totals
- Update cart count
- Broadcast to kitchen (if order already submitted)

**UI Elements:**
- "Add to Order" button
- Size selection modal
- Special instructions text area
- Cart icon with badge (item count)
- Toast notification: "Item added"

---

#### 5. Review Order (1 minute)

**Actions:**
1. Tap cart icon
2. Review items and quantities
3. Check total price
4. Edit items if needed (remove or change quantity)
5. Add more items if desired

**UI Elements:**
- Cart modal or page
- Item list with:
  - Name
  - Size
  - Price
  - Quantity
  - Remove button
- Subtotal
- Service charge
- Tax
- Total
- "Add More Items" button
- "Submit Order" button

---

#### 6. Submit Order (10 seconds)

**Actions:**
1. Tap "Submit Order" button
2. Confirm order submission

**System Actions:**
- Update order status to `ordered` (20)
- Update all order items to `ordered`
- Calculate final totals
- Create order action record (action: openorder)
- Broadcast to kitchen via WebSocket
- Update table status to `occupied`
- Send confirmation to customer

**UI Elements:**
- Confirmation dialog
- Success message: "Order submitted!"
- Order number display
- Estimated preparation time
- "Track Order" button

---

#### 7. Track Order Status (5-15 minutes)

**Display:**
- Order status indicator:
  - Ordered (red) - "Your order has been received"
  - Preparing (yellow) - "Your food is being prepared"
  - Ready (green) - "Your food is ready!"
  - Delivered (blue) - "Enjoy your meal!"

**System Actions:**
- WebSocket subscription to order channel
- Real-time status updates from kitchen
- Push notifications (if enabled)

**UI Elements:**
- Status timeline/progress bar
- Status icon and text
- Estimated time remaining
- Item list with individual statuses
- "Request Bill" button (appears when delivered)

---

#### 8. Request Bill (10 seconds)

**Actions:**
1. Tap "Request Bill" button
2. Confirm request

**System Actions:**
- Update order status to `billrequested` (30)
- Create order action record (action: requestbill)
- Notify server via WebSocket
- Generate bill/receipt

**UI Elements:**
- "Request Bill" button
- Confirmation dialog
- Success message: "Bill requested"
- Bill summary display

---

#### 9. Pay (1-2 minutes)

**Actions:**
1. Server brings payment terminal or provides payment link
2. Customer pays via:
   - Credit/debit card
   - Digital wallet (Apple Pay, Google Pay)
   - Cash (manual entry by server)
3. Payment processed

**System Actions:**
- Process payment via Stripe
- Update order status to `paid` (35)
- Generate receipt
- Send receipt via email/SMS (optional)
- Update order status to `closed` (40)
- Update table status to `free`

**UI Elements:**
- Payment link or QR code
- Stripe payment form
- Payment confirmation
- Receipt display
- "Download Receipt" button

---

### Success Metrics

- **Menu Load Time:** < 2 seconds
- **Order Placement Time:** < 5 minutes from scan to submit
- **Order Accuracy:** 98%+ correct items
- **Status Update Latency:** < 1 second
- **Payment Success Rate:** 99%+

---

## Journey 4: Kitchen Staff Managing Orders

**Persona:** Kitchen Manager/Staff  
**Goal:** Receive orders, prepare food, update status  
**Time:** Continuous throughout shift  
**Success Criteria:** All orders processed, status updated accurately, no missed orders

### Flow Diagram

```
Login → Kitchen Dashboard → Receive Order → Start Preparing → Mark Ready → Confirm Delivery → Repeat
```

### Detailed Steps

#### 1. Access Kitchen Dashboard (1 minute)

**Actions:**
1. Log in with employee credentials
2. Navigate to kitchen dashboard
3. View active orders

**System Actions:**
- Authenticate employee
- Verify kitchen staff role
- Load active orders (status: ordered, preparing, ready)
- Subscribe to kitchen WebSocket channel

**Dashboard Display:**
- Active order cards
- Order count by status
- Filters and sorting options
- Sound notification toggle

---

#### 2. Receive New Order (Real-time)

**System Actions:**
- New order broadcast via WebSocket
- Sound notification plays
- Order card appears in dashboard
- Order details displayed

**Order Card Display:**
- Table number (large, prominent)
- Order time
- Items list with quantities
- Special instructions
- Allergen warnings
- "Start Preparing" button

---

#### 3. Start Preparation (5 seconds)

**Actions:**
1. Review order details
2. Tap "Start Preparing" button

**System Actions:**
- Update order status to `preparing` (22)
- Update order items to `preparing`
- Broadcast status change
- Start preparation timer
- Move card to "Preparing" section

**UI Changes:**
- Card color changes to yellow
- Timer starts
- Button changes to "Mark Ready"

---

#### 4. Mark Ready (5 seconds)

**Actions:**
1. Food prepared
2. Tap "Mark Ready" button

**System Actions:**
- Update order status to `ready` (24)
- Update order items to `ready`
- Broadcast status change
- Notify server
- Move card to "Ready" section

**UI Changes:**
- Card color changes to green
- "Ready" badge displayed
- Button changes to "Mark Delivered"
- Sound notification (optional)

---

#### 5. Confirm Delivery (5 seconds)

**Actions:**
1. Server delivers food to table
2. Server or kitchen staff taps "Mark Delivered"

**System Actions:**
- Update order status to `delivered` (25)
- Update order items to `delivered`
- Broadcast status change
- Remove card from kitchen dashboard (optional)
- Update customer smart menu

**UI Changes:**
- Card removed or moved to "Completed" section
- Success notification

---

### Success Metrics

- **Order Receipt Latency:** < 1 second from submission
- **Status Update Accuracy:** 100%
- **Missed Orders:** 0
- **Average Preparation Time:** Track per item type
- **Dashboard Uptime:** 99.9%+

---

## Journey 5: Restaurant Owner Viewing Analytics

**Persona:** Restaurant Owner  
**Goal:** Gain insights into sales and performance  
**Time:** 5-10 minutes  
**Success Criteria:** Identify trends, popular items, revenue patterns

### Detailed Steps

#### 1. Access Analytics Dashboard (30 seconds)

**Actions:**
1. Log in to dashboard
2. Navigate to "Analytics" tab
3. Select date range (e.g., Last 30 Days)

**System Actions:**
- Load analytics data from materialized views
- Calculate key metrics
- Generate charts and graphs

---

#### 2. View Key Metrics (1 minute)

**Display:**
- Total Orders
- Total Revenue
- Average Order Value
- Popular Items (top 10)
- Revenue by Menu
- Orders by Status
- Customer Count

**Actions:**
1. Review high-level metrics
2. Compare to previous period
3. Identify trends

---

#### 3. Analyze Trends (2-3 minutes)

**Actions:**
1. View revenue over time (line chart)
2. Identify peak hours (heat map)
3. Compare menu performance
4. Analyze item popularity

**Charts:**
- Revenue line chart
- Orders bar chart
- Popular items pie chart
- Hourly heat map

---

#### 4. Export Data (1 minute)

**Actions:**
1. Select export format (CSV, PDF)
2. Click "Export"
3. Download file

---

## Journey 6: Managing Multi-Location Restaurant

**Persona:** Restaurant Owner (Multi-location)  
**Goal:** Manage multiple restaurant locations from single dashboard  
**Time:** Ongoing  
**Success Criteria:** All locations configured, menus deployed, orders tracked

### Key Features

- Switch between locations
- View aggregated analytics
- Copy menus between locations
- Manage staff per location
- Location-specific settings
- Consolidated reporting

---

## Next Document

Continue to **Part 4: Technical Specifications** (`04-technical-specs.md`) for detailed technical requirements and API specifications.
