# Test Selectors Reference

## Bottom Sheet Selectors
- Cart Total: `[data-testid="cart-total-amount"]` (NOT order-total-amount)
- Submit Button: `[data-testid="cart-submit-order-btn"]`
- Bottom Sheet: `#cartBottomSheet`
- Cart Items: `#cartItemsContainer`

## Payment Buttons (only when billrequested)
- Payment Buttons: `#cartPaymentButtons`
- Pay Button: `#cartPayOrder`
- Split Bill: `#cartSplitBill`

## Important Notes
- Payment buttons only render when `order.status == 'billrequested'`
- Use `assert_selector` with explicit waits, not timeouts
- Bottom sheet renders server-side, no DOM injection needed
