# Smart Menu - Product Requirements Document
# Part 2: Core Features & Functional Requirements

**Version:** 1.0  
**Last Updated:** October 26, 2025

---

## Table of Contents

1. [User Onboarding](#user-onboarding)
2. [Menu Management](#menu-management)
3. [OCR Menu Import](#ocr-menu-import)
4. [Smart Menu Deployment](#smart-menu-deployment)
5. [Customer Ordering](#customer-ordering)
6. [Order Management](#order-management)
7. [Kitchen Management](#kitchen-management)
8. [Inventory Management](#inventory-management)

---

## 1. User Onboarding

### 1.1 User Registration

**Authentication Methods:**
- Email/Password (Devise)
- OAuth (Google, Facebook, Spotify)
- Email verification required
- Password recovery with secure tokens

**Registration Flow:**
1. User visits homepage
2. Clicks "Sign Up"
3. Enters email and password
4. Receives verification email
5. Clicks verification link
6. Account activated
7. Redirected to onboarding wizard

### 1.2 Onboarding Wizard

**5-Step Progressive Disclosure:**

**Step 1: Account Details**
- **Fields:**
  - Full Name (required)
  - Email (pre-filled, verified)
- **Validation:** Name required
- **Analytics:** Track onboarding_started event
- **Progress:** 20%

**Step 2: Restaurant Details**
- **Fields:**
  - Restaurant Name (required)
  - Restaurant Type (dropdown: Fine Dining, Casual, Fast Food, Cafe, Bar, etc.)
  - Cuisine Type (dropdown: Italian, Chinese, Mexican, American, etc.)
  - Location/Address (required)
  - Phone Number (optional)
- **Validation:** Name, type, cuisine required
- **Analytics:** Track restaurant_details_completed event
- **Progress:** 40%

**Step 3: Plan Selection**
- **Display:**
  - All active subscription plans
  - Plan comparison table
  - Feature highlights per plan
  - Pricing (monthly/yearly toggle)
  - "Most Popular" badge on recommended plan
- **Fields:**
  - Plan selection (required)
- **Validation:** Plan must be selected
- **Analytics:** Track plan_selected event with plan details
- **Progress:** 60%

**Step 4: Menu Creation**
- **Fields:**
  - Menu Name (required)
  - Menu Items (dynamic list):
    - Item Name (required)
    - Price (required)
    - Description (optional)
  - Add Item button (minimum 1 item)
- **Validation:** Menu name and at least one item required
- **Analytics:** Track menu_created event with item count
- **Progress:** 80%

**Step 5: Completion**
- **Display:**
  - Success message
  - "Your restaurant is being set up" indicator
  - Preview of QR code
  - Next steps guidance
  - Dashboard access button
- **Background Processing:** `RestaurantOnboardingJob` creates:
  - Restaurant record
  - Menu record
  - Menu sections
  - Menu items
  - Default settings
  - Owner employee record
  - Smart menus with QR codes
- **Analytics:** Track onboarding_completed event
- **Progress:** 100%

### 1.3 Onboarding Features

**Session Persistence:**
- Wizard data stored in `onboarding_sessions` table
- JSON-serialized wizard_data field
- Resumable if user leaves and returns
- Status tracking (started, account_created, restaurant_details, plan_selected, menu_created, completed)

**Validation:**
- Step-by-step validation prevents progression with incomplete data
- Server-side validation on each step submission
- Client-side validation for immediate feedback
- Error messages displayed inline

**Auto-redirect:**
- Incomplete onboarding redirects to wizard on login
- `needs_onboarding?` check in ApplicationController
- Skips redirect for certain controllers (home, sessions, etc.)
- Allows AJAX requests to pass through

**Background Processing:**
- Restaurant creation happens asynchronously
- Prevents blocking user during setup
- Job retries on failure
- Error handling and logging

---

## 2. Menu Management

### 2.1 Menu Hierarchy

```
Restaurant
  └── Menu (1 to many)
      ├── Menu Properties
      ├── Menu Availabilities (time-based)
      └── Menu Section (1 to many)
          ├── Section Properties
          ├── Section Locales (translations)
          └── Menu Item (1 to many)
              ├── Item Properties
              ├── Item Locales (translations)
              ├── Sizes (S, M, L with price variants)
              ├── Allergens (Gluten, Dairy, Nuts, etc.)
              ├── Ingredients
              ├── Tags (Spicy, Chef's Special, etc.)
              ├── Images (uploaded or AI-generated)
              └── Inventory (optional, one-to-one)
```

### 2.2 Menu Properties

**Core Fields:**
- Name (string, required, max 255 chars)
- Description (text, optional)
- Status (enum: inactive=0, active=1, archived=2)
- Restaurant ID (foreign key, required)
- Sequence (integer, for ordering)
- Archived (boolean, soft delete)

**Display Settings:**
- Display Images (boolean, show item images)
- Display Images in Popup (boolean, modal view)
- Allow Ordering (boolean, enable customer orders)
- Inventory Tracking (boolean, enable stock management)

**Pricing Settings:**
- Currency (string, e.g., "USD", "EUR", "GBP")
- Cover Charge (decimal, per person charge)
- Service Charge Percentage (decimal, e.g., 10.0 for 10%)
- Tax Percentage (decimal, e.g., 8.5 for 8.5%)

**Timestamps:**
- Created At
- Updated At

### 2.3 Menu Section Properties

**Core Fields:**
- Name (string, required, max 255 chars)
- Description (text, optional)
- Menu ID (foreign key, required)
- Sequence (integer, for ordering)
- Status (enum: inactive=0, active=1, archived=2)

**Time Restrictions:**
- Restricted (boolean, time-limited availability)
- From Hour (integer, 0-23)
- From Minute (integer, 0-59)
- To Hour (integer, 0-23)
- To Minute (integer, 0-59)
- From Offset (integer, minutes from midnight)
- To Offset (integer, minutes from midnight)

**Localization:**
- Section Locales (has_many relationship)
  - Locale code (e.g., "en", "it")
  - Localized name
  - Localized description

### 2.4 Menu Item Properties

**Core Fields:**
- Name (string, required, max 255 chars)
- Description (text, optional)
- Price (decimal, required, precision: 10, scale: 2)
- Menu Section ID (foreign key, required)
- Sequence (integer, for ordering)
- Status (enum: inactive=0, active=1, archived=2)

**Item Details:**
- Item Type (enum: food=0, beverage=1, wine=2)
- Preparation Time (integer, minutes)
- Calories (integer)
- Image (Active Storage attachment)

**Dietary Flags:**
- Is Vegetarian (boolean)
- Is Vegan (boolean)
- Is Gluten Free (boolean)
- Is Dairy Free (boolean)

**Relationships:**
- Allergens (many-to-many via menuitem_allergyn_mappings)
- Ingredients (many-to-many via menuitem_ingredient_mappings)
- Tags (many-to-many via menuitem_tag_mappings)
- Sizes (many-to-many via menuitem_size_mappings with price variants)
- Inventory (one-to-one, optional)
- Generated Image (one-to-one, AI-generated)

**Localization:**
- Item Locales (has_many relationship)
  - Locale code
  - Localized name
  - Localized description

### 2.5 Menu Operations

**CRUD Operations:**
- Create menu
- Read/view menu
- Update menu properties
- Delete/archive menu
- Duplicate menu

**Section Operations:**
- Add section to menu
- Edit section
- Reorder sections (drag-and-drop, updates sequence)
- Delete/archive section
- Move section to different menu

**Item Operations:**
- Add item to section
- Edit item
- Reorder items within section
- Delete/archive item
- Move item to different section
- Duplicate item

**Bulk Operations:**
- Activate multiple items
- Deactivate multiple items
- Archive multiple items
- Delete multiple items
- Export menu data (CSV, JSON)
- Import menu data

**Image Management:**
- Upload custom images (JPG, PNG, WebP)
- Generate AI images via DALL-E
- Automatic WebP conversion
- Responsive image variants (thumbnail, medium, large)
- Image optimization
- Lazy loading support
- Regenerate WebP derivatives
- Generate AI images for all items

**Localization Management:**
- Add locale to restaurant
- Add translations for menu
- Add translations for sections
- Add translations for items
- Set default locale
- Manage locale availability

---

## 3. OCR Menu Import

### 3.1 PDF Upload & Processing

**Upload Interface:**
- Drag-and-drop PDF upload
- File browser selection
- File size limit (configurable, default 10MB)
- Supported formats: PDF only
- Progress indicator during upload

**Processing Flow:**
1. **Upload:** PDF attached to OcrMenuImport record
2. **Queue:** PdfMenuExtractionJob enqueued
3. **Extract:** Text extraction via dual strategy
4. **Parse:** AI parsing via ChatGPT
5. **Save:** Structured data saved to database
6. **Complete:** Status updated, user notified

### 3.2 Text Extraction (Dual Strategy)

**Strategy 1: Text-Based PDFs**
- Use PDF::Reader to extract selectable text
- Check each page for extractable text
- If > 60% of pages have text, treat as text-based
- Fast and accurate for digital PDFs

**Strategy 2: Image-Based PDFs**
- Convert PDF pages to images (PNG, 300 DPI)
- Use Google Cloud Vision OCR on each image
- Extract text from image annotations
- Slower but handles scanned menus

**Page Processing:**
- Track progress (processed_pages / total_pages)
- Update progress in real-time
- Handle multi-page menus
- Preserve page boundaries with form feed characters

### 3.3 AI Parsing with ChatGPT

**Prompt Engineering:**
- Structured prompt requesting JSON output
- Schema definition for sections and items
- Instructions for handling unknowns (use null)
- Strict rules to avoid markdown code fences

**Expected JSON Structure:**
```json
{
  "sections": [
    {
      "name": "Appetizers",
      "items": [
        {
          "name": "Bruschetta",
          "description": "Toasted bread with tomatoes",
          "price": 8.99,
          "allergens": ["gluten", "dairy"],
          "is_vegetarian": true,
          "is_vegan": false,
          "is_gluten_free": false,
          "is_dairy_free": false
        }
      ]
    }
  ]
}
```

**Error Handling:**
- Fallback to empty structure if API fails
- Retry logic for network errors (3 attempts)
- Timeout handling (120 seconds default)
- JSON parsing with cleanup (remove code fences)
- Graceful degradation

### 3.4 Confirmation Interface

**Display:**
- List of extracted sections
- List of items per section
- Inline editing capability
- Confirmation checkboxes
- Reorder controls (drag-and-drop)

**Editing Features:**
- Edit item name
- Edit description
- Edit price
- Edit allergens
- Add/remove items
- Add/remove sections
- Reorder sections
- Reorder items within sections

**Confirmation Actions:**
- Confirm individual items
- Confirm entire sections
- Bulk confirm all
- Toggle confirmation status
- Unconfirm items

**Validation:**
- Required fields highlighted
- Price format validation
- Duplicate detection
- Missing data warnings

**Import Actions:**
- Import to existing menu
- Import to new menu
- Cancel import
- Delete import

### 3.5 Import to Menu Service

**Import Process:**
1. Validate confirmed items
2. Create or update menu
3. Create or update sections
4. Create or update items
5. Link allergens, ingredients, sizes
6. Set dietary flags
7. Set sequence numbers
8. Update statistics

**Upsert Logic:**
- Find existing items by name + sequence
- Update if found, create if not
- Preserve existing data not in import
- Track created vs updated counts

**Statistics Tracking:**
- Sections created
- Sections updated
- Items created
- Items updated
- Total processing time

---

## 4. Smart Menu Deployment

### 4.1 Smart Menu Generation

**Automatic Generation:**
- Triggered by `SmartMenuGeneratorJob`
- Creates smart menus for each menu
- Creates smart menus for each table
- Creates smart menus for each table-menu combination

**Smart Menu Types:**

**Type 1: General Menu**
- No table assignment
- Browse-only mode
- No ordering capability
- Public access
- URL: `/smartmenus/{slug}`

**Type 2: Table + Menu**
- Specific table and menu
- Full ordering capability
- Session-based participant tracking
- Order creation and management
- URL: `/smartmenus/{slug}` (with table and menu IDs)

**Type 3: Table-only**
- Specific table, no menu
- Menu selection interface
- Access to all restaurant menus
- Order capability after menu selection
- URL: `/smartmenus/{slug}` (with table ID only)

### 4.2 Smart Menu Properties

**Core Fields:**
- Slug (string, UUID, unique, indexed)
- Restaurant ID (foreign key, required)
- Menu ID (foreign key, optional)
- Table Setting ID (foreign key, optional)
- Created At
- Updated At

**Relationships:**
- Belongs to Restaurant
- Belongs to Menu (optional)
- Belongs to Table Setting (optional)
- Has many Menu Participants
- Has many Order Participants (through orders)

### 4.3 QR Code System

**QR Code Generation:**
- Unique QR code per smart menu slug
- QR code contains full URL: `https://domain.com/smartmenus/{slug}`
- Generated using RQRCode gem
- SVG format for scalability
- PNG export capability

**QR Code Display:**
- Downloadable formats (PNG, PDF, SVG)
- Printable templates
- Customizable size
- High contrast for scanning
- Error correction level: M (medium)

**QR Code Deployment Options:**
- Table tents (folded cards)
- Table stickers (adhesive labels)
- Wall posters (A4/Letter size)
- Receipt inserts
- Digital displays (tablets, screens)

**QR Code Management:**
- View all QR codes for restaurant
- Download individual QR codes
- Download bulk QR codes (ZIP)
- Regenerate QR codes
- Track QR code scans (analytics)
- Disable/enable smart menus
- Archive old QR codes

### 4.4 Table Settings

**Table Properties:**
- Name/Number (string, required, e.g., "Table 1", "A5")
- Description (text, optional)
- Table Type (enum: indoor=1, outdoor=2)
- Capacity (integer, required, number of seats)
- Status (enum: free=0, occupied=1, archived=2)
- Sequence (integer, for ordering)
- Restaurant ID (foreign key, required)

**Table Management:**
- Add new table
- Edit table details
- Delete/archive table
- Bulk activate tables
- Bulk deactivate tables
- Bulk archive tables
- Reorder tables
- View table status

**Table Status Management:**
- Automatic status update on order creation (free → occupied)
- Manual status update by staff
- Real-time status display
- Visual seating plan for staff
- Table availability tracking

**Table-Smart Menu Linking:**
- Automatic smart menu generation per table
- One smart menu per table-menu combination
- QR code specific to table
- Session tracking per table
- Order association with table

---

## 5. Customer Ordering

### 5.1 Smart Menu Interface

**Access Flow:**
1. Customer scans QR code at table
2. Smart menu loads in mobile browser (no app required)
3. Session created with unique session ID
4. Menu displays with customer's device language (auto-detect)
5. Customer can browse, filter, and order

**Interface Features:**
- **Responsive Design:** Mobile-first, tablet and desktop support
- **Fast Loading:** < 2 seconds initial load
- **Offline Capability:** Basic menu browsing without connection
- **Progressive Enhancement:** Works on all browsers
- **Accessibility:** WCAG 2.1 AA compliant

**Navigation:**
- Sticky header with restaurant name
- Section navigation (jump to section)
- Scroll spy (highlight current section)
- Back to top button
- Search functionality

**Visual Design:**
- High-quality menu item images
- Lazy loading for performance
- Image placeholders during load
- Responsive image sizes
- WebP format with fallbacks

### 5.2 Order Participant System

**Session Management:**
- Unique session ID per customer device (Rails session ID)
- Persistent across page reloads
- Stored in browser session
- No login required for customers

**Participant Creation:**
- Automatic on first smart menu access
- Links to order when order is created
- Tracks customer preferences
- Records order actions

**Participant Properties:**
- Session ID (string, unique identifier)
- Role (enum: customer=0, staff=1)
- Preferred Locale (string, e.g., "en", "it")
- Order ID (foreign key, optional)
- Order Item ID (foreign key, optional)
- Employee ID (foreign key, optional, for staff)
- Allergen Filters (many-to-many with allergyns)

**Participant Tracking:**
- Order participation (who joined order)
- Items added by participant
- Locale preferences
- Dietary filter preferences
- Order actions (view, add, remove, request bill)

### 5.3 Multi-Language Support

**Supported Languages:**
- English (en) - Default
- Italian (it)
- Extensible to additional languages

**Translation System:**
- Restaurant-level locale configuration
- Menu-level translations (menu name)
- Section-level translations (section names)
- Item-level translations (item names and descriptions)
- Automatic fallback to default language if translation missing

**Locale Switching:**
- Language selector in smart menu header
- Flag icons for visual recognition
- Dropdown with language names
- Instant UI update without page reload
- Preference stored in participant session
- Persists across page navigation

**Auto-Detection:**
- HTTP Accept-Language header parsing
- Browser language detection
- Fallback to restaurant default locale
- Fallback to English if unsupported language

### 5.4 Dietary Restrictions & Allergen Filtering

**Supported Dietary Filters:**
- Vegetarian (is_vegetarian flag)
- Vegan (is_vegan flag)
- Gluten-Free (is_gluten_free flag)
- Dairy-Free (is_dairy_free flag)

**Allergen System:**
- Restaurant-level allergen catalog (Gluten, Dairy, Nuts, Shellfish, Eggs, Soy, Fish, etc.)
- Item-level allergen tagging (many-to-many)
- Customer allergen filter selection
- Auto-hide items with selected allergens
- Clear allergen warnings on items

**Filter Interface:**
- Filter button in header
- Modal with filter options
- Checkbox selection
- Apply filters button
- Clear filters button
- Active filter indicators

**Filter Persistence:**
- Filters saved to participant session
- Maintained across page navigation
- Applied automatically to all menu views
- Persists until session ends or filters cleared

**Filter Logic:**
- Items with selected allergens are hidden
- Items matching dietary filters are shown
- Combine filters with AND logic (all must match)
- Show item count after filtering

---

## 6. Order Management

### 6.1 Order Lifecycle

**Order States (Enum):**
```
opened (0)         - Order created, items being added
ordered (20)       - Order submitted to kitchen
preparing (22)     - Kitchen preparing food
ready (24)         - Food ready for serving
delivered (25)     - Food delivered to table
billrequested (30) - Customer requested bill
paid (35)          - Bill paid
closed (40)        - Order completed and closed
```

**State Machine (AASM):**
- **order:** opened → ordered
- **start_preparing:** ordered → preparing
- **mark_ready:** preparing → ready
- **mark_delivered:** ready → delivered
- **requestbill:** any → billrequested
- **paybill:** billrequested → paid
- **close:** paid → closed

**State Transition Rules:**
- Orders can only move forward (no backward transitions)
- Bill can be requested from any active state
- Payment requires bill request first
- Closing requires payment first

### 6.2 Order Properties

**Core Fields:**
- Restaurant ID (foreign key, required)
- Menu ID (foreign key, required)
- Table Setting ID (foreign key, required)
- Employee ID (foreign key, optional, for staff orders)
- Status (enum, default: opened)
- Archived (boolean, soft delete)

**Pricing Fields:**
- Net Amount (decimal, sum of item prices)
- Service Charge (decimal, calculated from percentage)
- Tax (decimal, calculated from percentage)
- Tip (decimal, customer-entered)
- Gross Total (decimal, net + service + tax + tip)

**Timestamps:**
- Created At (order date/time)
- Updated At

**Relationships:**
- Belongs to Restaurant
- Belongs to Menu
- Belongs to Table Setting
- Belongs to Employee (optional)
- Has many Order Items
- Has many Order Participants
- Has many Order Actions

### 6.3 Order Items

**Order Item Properties:**
- Order ID (foreign key, required)
- Menu Item ID (foreign key, required)
- Order Item Price (decimal, snapshot of price at order time)
- Status (enum, mirrors order status)
- Quantity (integer, default: 1)
- Size ID (foreign key, optional)

**Relationships:**
- Belongs to Order
- Belongs to Menu Item
- Has one Order Participant (who added the item)
- Has many Order Item Notes

**Item Status:**
- Items inherit parent order status
- Status cascades from order to items
- Individual item status can be tracked
- Item removal sets status to "removed" (10)

**Order Item Notes:**
- Customer special requests
- Dietary modifications
- Cooking preferences
- Allergy warnings
- Kitchen notes

### 6.4 Order Calculations

**Pricing Formula:**
```
Net Amount = Sum of (Order Item Price × Quantity)
Service Charge = Net Amount × (Service % / 100)
Tax = (Net Amount + Service Charge) × (Tax % / 100)
Tip = Customer-entered amount
Gross Total = Net Amount + Service Charge + Tax + Tip
```

**Calculation Triggers:**
- On order creation
- On item addition
- On item removal
- On order update
- On tip entry

**Currency Formatting:**
- Use restaurant's currency setting
- Format with appropriate symbol ($, €, £, etc.)
- Decimal precision (2 places)
- Thousand separators (locale-specific)

### 6.5 Order Actions (Audit Trail)

**Action Types (Enum):**
```
participate (0)   - Customer joined order
openorder (1)     - Order created
additem (2)       - Item added to order
removeitem (3)    - Item removed from order
requestbill (4)   - Bill requested
closeorder (5)    - Order closed
```

**Order Action Properties:**
- Order Participant ID (foreign key, required)
- Order ID (foreign key, required)
- Order Item ID (foreign key, optional)
- Action (enum, required)
- Created At (timestamp)

**Audit Trail Benefits:**
- Track who performed each action
- Identify order issues and disputes
- Analytics on ordering patterns
- Customer behavior insights
- Staff performance tracking

---

## 7. Kitchen Management

### 7.1 Kitchen Dashboard

**Dashboard Features:**
- Real-time order display
- Active orders (Ordered, Preparing, Ready)
- Order details (table, items, time)
- Order status indicators (color-coded)
- Priority markers (oldest orders highlighted)
- Estimated preparation time

**Order Display:**
- Card-based layout
- Large, readable text
- Color-coded by status:
  - Red: Ordered (new)
  - Yellow: Preparing (in progress)
  - Green: Ready (for serving)
- Order age indicator (time since ordered)
- Table number prominent
- Item list with quantities

**Filtering & Sorting:**
- Filter by status
- Filter by table
- Sort by time (oldest first)
- Sort by table number
- Search by order ID

**Auto-Refresh:**
- WebSocket real-time updates
- No manual refresh needed
- Instant notification of new orders
- Automatic status updates

### 7.2 Kitchen Actions

**Status Management:**
- **Start Preparing:** Click button to mark order as preparing
- **Mark Ready:** Click button to mark food ready for serving
- **Mark Delivered:** Click button to confirm delivery (usually by server)

**Action Buttons:**
- Large, touch-friendly buttons
- Color-coded by action
- Confirmation dialogs for critical actions
- Keyboard shortcuts for efficiency

**Notifications:**
- Sound alerts for new orders
- Visual alerts (flashing, color change)
- Badge counters for pending orders
- Toast notifications for status changes

### 7.3 Real-Time Communication

**WebSocket Integration (Action Cable):**
- Kitchen channel subscription
- Restaurant-specific channels
- Table-specific channels
- Order-specific channels

**Broadcast Events:**
- New order created
- Order status changed
- Order item added
- Order item removed
- Bill requested
- Order closed

**Broadcast Targets:**
- Kitchen dashboard
- Server devices
- Customer smart menu
- Manager dashboard

**Connection Management:**
- Automatic reconnection on disconnect
- Connection status indicator
- Fallback to polling if WebSocket unavailable
- Minimal latency (< 1 second)

---

## 8. Inventory Management

### 8.1 Inventory Tracking

**Inventory Properties:**
- Menu Item ID (foreign key, one-to-one)
- Starting Inventory (integer, initial stock level)
- Current Inventory (integer, real-time count)
- Reset Hour (integer, 0-23, when inventory resets)
- Status (enum: inactive=0, active=1)

**Inventory Operations:**
- Set initial stock levels
- Manual inventory adjustments (add/subtract)
- Automatic deduction on order
- Scheduled resets (daily, weekly)
- Low stock alerts
- Out of stock handling

### 8.2 Inventory Integration

**Menu Item Linking:**
- Enable inventory tracking toggle on menu item
- One-to-one relationship (one inventory per item)
- Set stock levels during item creation or later
- Configure reset schedule

**Order Integration:**
- Automatic inventory deduction when item ordered
- Real-time stock updates
- Prevent ordering when out of stock (current inventory = 0)
- Auto-disable items at zero stock (optional)
- Re-enable items on inventory reset

**Inventory Resets:**
- Scheduled daily resets at specified hour
- Manual reset capability
- Reset to starting inventory level
- Reset history tracking
- Notification on reset (optional)

### 8.3 Inventory Dashboard

**Inventory View:**
- Table view of all inventory items
- Current stock levels
- Starting inventory levels
- Reset time
- Status (active/inactive)
- Last updated timestamp

**Filtering & Sorting:**
- Filter by status
- Filter by stock level (low, out of stock)
- Sort by name
- Sort by current inventory
- Sort by last updated

**Bulk Operations:**
- Activate multiple items
- Deactivate multiple items
- Reset multiple inventories
- Export inventory data (CSV)
- Import inventory updates (CSV)

**Alerts:**
- Low stock warnings (configurable threshold)
- Out of stock alerts
- Items approaching reset time
- Items with inventory tracking disabled

---

## Next Document

Continue to **Part 3: User Journeys & Workflows** (`03-user-journeys.md`) for detailed user flow diagrams and scenarios.
