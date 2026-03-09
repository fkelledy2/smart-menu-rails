# Split Bill Feature - Testing Guide

## Quick Start

### Prerequisites
- Order in `billrequested` status
- Multiple participants at the table (2+ customers with active sessions)
- Restaurant with Stripe or Square payment provider configured

### Basic Test Flow
1. Navigate to Smart Menu: `http://localhost:3000/smartmenus/{uuid}`
2. Add items to cart and request bill
3. Click "Split Bill" button in cart bottom sheet
4. Select split method and configure
5. Create split plan
6. Pay your share
7. Verify in staff order view

---

## Customer-Facing Tests

### Test 1: Equal Split
**Objective**: Verify equal split divides total evenly with correct rounding

**Steps**:
1. Click "Split Bill" button
2. Verify "Equal" method is selected by default
3. Check all participants are listed with "(You)" indicator
4. Verify equal split preview shows: `Total / Participant Count`
5. Click "Create Split"
6. Verify plan is created and frozen
7. Verify "Pay My Share" button appears
8. Click "Pay My Share"
9. Verify redirect to Stripe/Square checkout with correct amount

**Expected Results**:
- ✅ Amount per person = Total / Number of participants
- ✅ Rounding handled correctly (no missing/extra cents)
- ✅ Plan becomes frozen after creation
- ✅ Checkout amount matches displayed share

---

### Test 2: Custom Amount Split
**Objective**: Verify custom amounts with validation

**Steps**:
1. Click "Split Bill" button
2. Select "Custom" method
3. Enter custom amounts for each participant
4. Verify total updates in real-time
5. Verify total turns **green** when it matches order total
6. Verify total turns **red** when it doesn't match
7. Try to create plan with mismatched total
8. Verify validation error appears
9. Fix amounts to match total
10. Click "Create Split"

**Expected Results**:
- ✅ Real-time total calculation
- ✅ Visual feedback (green/red) for valid/invalid totals
- ✅ Cannot create plan with mismatched total
- ✅ Detailed error message shows difference amount
- ✅ Plan creates successfully when totals match

**Test Cases**:
- Total too high by €5.00 → Error: "off by €5.00"
- Total too low by €2.50 → Error: "off by €2.50"
- Empty inputs → Error: "Enter an amount for each participant"
- Exact match → Success

---

### Test 3: Percentage Split
**Objective**: Verify percentage split with 100% validation

**Steps**:
1. Click "Split Bill" button
2. Select "%" (Percentage) method
3. Enter percentages for each participant
4. Verify total updates in real-time
5. Verify total turns **green** when it equals 100%
6. Verify total turns **red** when it doesn't equal 100%
7. Try to create plan with total ≠ 100%
8. Verify validation error appears
9. Fix percentages to total 100%
10. Click "Create Split"

**Expected Results**:
- ✅ Real-time percentage total calculation
- ✅ Visual feedback (green/red) for valid/invalid totals
- ✅ Cannot create plan unless total = 100%
- ✅ Detailed error message shows current percentage
- ✅ Plan creates successfully when total = 100%
- ✅ Backend calculates correct amounts from percentages

**Test Cases**:
- 50% + 50% = 100% → Success
- 33.3% + 33.3% + 33.4% = 100% → Success
- 40% + 40% = 80% → Error: "currently 80.0%"
- 60% + 60% = 120% → Error: "currently 120.0%"

---

### Test 4: Item-Based Split
**Objective**: Verify item assignment with validation

**Steps**:
1. Click "Split Bill" button
2. Select "By Item" method
3. Verify all order items are listed
4. Assign each item to a participant using dropdown
5. Try to create plan with unassigned items
6. Verify validation error appears
7. Assign all items
8. Click "Create Split"

**Expected Results**:
- ✅ All payable order items displayed
- ✅ Dropdown shows all selected participants
- ✅ Cannot create plan with unassigned items
- ✅ Error message: "All items must be assigned to a participant"
- ✅ Plan creates successfully when all items assigned
- ✅ Tax/tip/service allocated proportionally to item values

---

### Test 5: Realtime Updates
**Objective**: Verify WebSocket updates when plan changes

**Setup**: Two browser windows with different participants

**Steps**:
1. Window A: Create split plan (any method)
2. Window B: Verify split plan appears automatically
3. Window B: Verify frozen state UI shows
4. Window A: Pay share (initiate checkout)
5. Window B: Verify plan status updates
6. Complete payment in Window A
7. Window B: Verify share status updates to "succeeded"

**Expected Results**:
- ✅ Plan appears in Window B without refresh
- ✅ Frozen state UI renders correctly
- ✅ Payment status updates propagate via WebSocket
- ✅ Console shows: `[SplitBill] Plan updated via WebSocket`

---

### Test 6: Cancel and Back Navigation
**Objective**: Verify cancel button restores UI state

**Steps**:
1. Click "Split Bill" button
2. Verify split bill section opens
3. Verify payment buttons hidden
4. Click "Cancel" button
5. Verify split bill section closes
6. Verify payment buttons reappear
7. Verify bottom sheet collapses to half state

**Expected Results**:
- ✅ Split bill section hidden
- ✅ Payment buttons visible again
- ✅ No error messages shown
- ✅ Method reset to "equal"
- ✅ Bottom sheet returns to half state

---

### Test 7: Error Handling
**Objective**: Verify comprehensive error messages

**Test Cases**:

**No participants selected**:
- Uncheck all participants
- Try to create plan
- Expected: "Select at least one participant"

**Network error**:
- Disconnect network
- Try to create plan
- Expected: "Failed to load order: 500" or similar

**Invalid response**:
- Backend returns error
- Expected: Error message from backend displayed

**Missing data**:
- Order not found
- Expected: "Failed to load order: 404"

---

## Staff-Facing Tests

### Test 8: Staff Order View - Split Bill Status
**Objective**: Verify staff can monitor split bill progress

**Steps**:
1. Create split plan as customer
2. Navigate to staff order view: `/restaurants/{id}/ordrs/{order_id}`
3. Scroll to "Split Bill Status" section
4. Verify all details displayed

**Expected Results**:
- ✅ Split method badge (Equal/Custom/Percentage/Item-Based)
- ✅ Plan status badge (Draft/Validated/Frozen/Completed)
- ✅ Frozen indicator if applicable
- ✅ Participant count
- ✅ Payment shares table with:
  - Participant identification
  - Share amounts
  - Payment status badges
  - Provider (Stripe/Square)
  - Provider payment IDs
- ✅ Settlement progress: "X/Y Settled"
- ✅ Total amount matches order total
- ✅ Frozen timestamp if applicable

---

### Test 9: Multi-Participant Payment Flow
**Objective**: Verify complete flow with multiple participants paying

**Setup**: 3 participants, €90 order (€30 each equal split)

**Steps**:
1. Participant 1: Create equal split plan
2. Staff: Verify plan shows in order view
3. Participant 1: Pay share (€30)
4. Staff: Verify 1/3 settled
5. Participant 2: Pay share (€30)
6. Staff: Verify 2/3 settled
7. Participant 3: Pay share (€30)
8. Staff: Verify 3/3 settled
9. Staff: Verify order marked as `paid`

**Expected Results**:
- ✅ Each payment updates settlement count
- ✅ Provider payment IDs recorded
- ✅ Status badges update (requires_payment → pending → succeeded)
- ✅ Order becomes `paid` only after all shares settled
- ✅ Total settled amount = order total

---

## Edge Cases & Error Scenarios

### Test 10: Frozen Plan Behavior
**Objective**: Verify plan cannot be modified after freezing

**Steps**:
1. Create split plan
2. Verify plan is frozen
3. Try to modify plan (should not be possible via UI)
4. Verify frozen indicator shown
5. Verify only "Pay My Share" action available

**Expected Results**:
- ✅ Method selector hidden
- ✅ Participant selection hidden
- ✅ Only frozen plan view shown
- ✅ "Pay My Share" button enabled if share unpaid
- ✅ Backend rejects modification attempts

---

### Test 11: Participant Without Session
**Objective**: Verify handling of participants without active sessions

**Steps**:
1. Create order with multiple participants
2. One participant closes browser (session expires)
3. Other participant creates split plan
4. Verify only active participants shown

**Expected Results**:
- ✅ Only participants with `sessionid` shown
- ✅ Expired participants filtered out
- ✅ Split plan creates successfully

---

### Test 12: Order State Validation
**Objective**: Verify split bill only available for billrequested orders

**Test Cases**:
- Order status: `opened` → Split Bill button hidden
- Order status: `billrequested` → Split Bill button visible
- Order status: `paid` → Split Bill button hidden
- Order status: `closed` → Split Bill button hidden

---

## Performance & Load Tests

### Test 13: Large Order (20+ Items)
**Objective**: Verify performance with many items

**Steps**:
1. Create order with 20+ items
2. Request bill
3. Click "Split Bill"
4. Select "By Item" method
5. Verify all items load quickly
6. Assign items and create plan

**Expected Results**:
- ✅ Items load in < 2 seconds
- ✅ UI remains responsive
- ✅ Dropdowns render correctly
- ✅ Plan creates successfully

---

### Test 14: Many Participants (5+)
**Objective**: Verify handling of large groups

**Steps**:
1. Create order with 5+ participants
2. Click "Split Bill"
3. Select "Custom" method
4. Enter amounts for all participants
5. Create plan

**Expected Results**:
- ✅ All participants listed
- ✅ Input fields render correctly
- ✅ Scrolling works if needed
- ✅ Total calculation accurate
- ✅ Plan creates successfully

---

## Browser Compatibility

### Test 15: Cross-Browser Testing
**Browsers to Test**:
- ✅ Chrome (latest)
- ✅ Safari (latest)
- ✅ Firefox (latest)
- ✅ Mobile Safari (iOS)
- ✅ Mobile Chrome (Android)

**Key Features to Verify**:
- Radio button groups render correctly
- Number inputs work properly
- WebSocket connections stable
- Bottom sheet animations smooth
- Touch interactions responsive (mobile)

---

## Regression Tests

### Test 16: Existing Payment Flow
**Objective**: Verify regular payment still works

**Steps**:
1. Add items to cart
2. Request bill
3. Click "Pay" button (not "Split Bill")
4. Verify regular checkout flow
5. Complete payment

**Expected Results**:
- ✅ Regular payment unaffected
- ✅ No split plan created
- ✅ Order marked as `paid` normally

---

### Test 17: Staff Equal Split (Legacy)
**Objective**: Verify staff equal split still works

**Steps**:
1. Navigate to staff order payments view
2. Use existing equal split functionality
3. Verify split plan created
4. Verify customers can pay shares

**Expected Results**:
- ✅ Staff equal split creates OrdrSplitPlan
- ✅ Uses same backend service
- ✅ Customers can pay via Smart Menu

---

## Debugging Tips

### Console Logs to Monitor
```javascript
[SplitBill] Order response: {...}
[SplitBill] Plan updated via WebSocket
[State] Split Bill clicked
[State] Split section found: true
```

### Common Issues

**"Split section found: false"**
- Hard refresh browser (Cmd+Shift+R)
- Check state_controller.js includes split section in rendered HTML

**404 on participants endpoint**
- Verify routes.rb has nested ordrparticipants index
- Restart Rails server

**Empty JSON response**
- Check Pundit policy allows anonymous users to view orders
- Verify @ordr is set in controller

**WebSocket not updating**
- Check ActionCable connection in browser console
- Verify SmartmenuState includes splitPlan in payload

---

## Success Criteria

### Customer Experience
- ✅ Intuitive UI with clear method selection
- ✅ Real-time validation feedback
- ✅ Helpful error messages
- ✅ Smooth transitions and animations
- ✅ Works on mobile devices
- ✅ Realtime updates without refresh

### Staff Experience
- ✅ Clear visibility of split plan status
- ✅ Per-participant payment tracking
- ✅ Settlement progress at a glance
- ✅ Provider payment ID references

### Technical
- ✅ No JavaScript errors in console
- ✅ All API calls succeed
- ✅ WebSocket connections stable
- ✅ Correct amounts calculated
- ✅ No missing/extra cents
- ✅ Frozen plans cannot be modified
- ✅ Order marked paid only when all shares settled

---

## Automated Testing (Future)

### Recommended Test Coverage
- [ ] Model tests for split plan calculator
- [ ] Controller tests for split plan endpoints
- [ ] System tests for customer split bill flow
- [ ] Integration tests for WebSocket updates
- [ ] Request tests for authorization rules
- [ ] Service tests for validation logic

---

**Last Updated**: March 9, 2026
**Feature Status**: Production Ready
**Documentation**: See `docs/features/in-progress/bill-splitting-feature-request.md`
