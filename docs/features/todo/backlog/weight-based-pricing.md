# Weight-Based Menu Item Pricing

## Overview
Enable restaurants to price menu items based on weight (e.g., steak priced per 100g), allowing customers to select their desired portion size and see the calculated price dynamically.

## Business Value
- **Premium dining**: Enables fine dining restaurants to offer premium cuts priced by weight
- **Flexibility**: Customers can choose exact portion sizes to match appetite and budget
- **Transparency**: Clear pricing structure builds trust with customers
- **Revenue optimization**: Encourages larger portions while maintaining margin control

## User Stories

### Restaurant Manager
- As a restaurant manager, I want to configure menu items with weight-based pricing so that customers can order custom portion sizes
- As a restaurant manager, I want to set a base unit (e.g., 100g, 1kg) and price per unit so pricing is consistent
- As a restaurant manager, I want to set minimum and maximum weight limits to control portion sizes
- As a restaurant manager, I want to see weight-based items clearly marked in my menu management interface

### Customer
- As a customer, I want to see items priced per weight unit (e.g., "€45 per 100g") so I understand the pricing structure
- As a customer, I want to select my desired weight/portion size when ordering
- As a customer, I want to see the total price update automatically as I adjust the weight
- As a customer, I want to see suggested portion sizes (e.g., 200g, 300g, 400g) for guidance

### Kitchen Staff
- As kitchen staff, I want to see the exact weight ordered on the kitchen display so I can prepare the correct portion
- As kitchen staff, I want weight-based items clearly marked on order tickets

## Technical Requirements

### Data Model Changes

#### Menuitem Model
```ruby
# New fields
add_column :menuitems, :pricing_type, :integer, default: 0  # enum: standard, weight_based
add_column :menuitems, :price_per_unit, :decimal, precision: 10, scale: 2
add_column :menuitems, :weight_unit, :string  # '100g', '1kg', etc.
add_column :menuitems, :min_weight, :decimal, precision: 8, scale: 2
add_column :menuitems, :max_weight, :decimal, precision: 8, scale: 2
add_column :menuitems, :default_weight, :decimal, precision: 8, scale: 2

# Enums
enum pricing_type: { standard: 0, weight_based: 1 }
```

#### Ordritem Model
```ruby
# New fields
add_column :ordritems, :ordered_weight, :decimal, precision: 8, scale: 2
add_column :ordritems, :actual_weight, :decimal, precision: 8, scale: 2  # For kitchen staff to confirm
```

### UI/UX Requirements

#### Menu Item Management
- Toggle between standard and weight-based pricing
- Price per unit input field
- Weight unit selector (100g, 50g, 1kg, etc.)
- Min/max weight validation
- Default weight setting
- Preview of how pricing displays to customers

#### Customer Ordering Interface
- Weight selector with slider and input field
- Real-time price calculation
- Suggested portion size buttons
- Clear display of price per unit
- Visual indicator for weight-based items

#### Kitchen Display
- Show ordered weight prominently
- Field to enter actual weight (for verification)
- Price recalculation if actual weight differs

### API Changes

#### Menu Item Endpoints
```json
{
  "id": 123,
  "name": "Ribeye Steak",
  "pricing_type": "weight_based",
  "price_per_unit": 4.50,
  "weight_unit": "100g",
  "min_weight": 150,
  "max_weight": 500,
  "default_weight": 250
}
```

#### Order Item Creation
```json
{
  "menuitem_id": 123,
  "ordered_weight": 250,
  "calculated_price": 11.25
}
```

### Business Logic

#### Price Calculation
```ruby
def calculate_price(weight)
  return price unless weight_based?
  
  weight_in_units = weight / unit_multiplier
  price_per_unit * weight_in_units
end

private

def unit_multiplier
  case weight_unit
  when '100g' then 100
  when '1kg' then 1000
  when '50g' then 50
  else 100
  end
end
```

#### Validation Rules
- Weight must be within min/max limits
- Price per unit must be positive
- Weight unit must be from predefined list
- Default weight must be within limits

## Implementation Phases

### Phase 1: Backend Foundation
1. Add database migrations
2. Update models with new fields and validations
3. Create price calculation service
4. Update API endpoints

### Phase 2: Admin Interface
1. Menu item form updates
2. Weight-based item indicators
3. Validation and error handling

### Phase 3: Customer Interface
1. Smart menu weight selector
2. Real-time price updates
3. Mobile-responsive design

### Phase 4: Kitchen Integration
1. KDS weight display
2. Actual weight confirmation
3. Price adjustment workflow

## Testing Requirements

### Unit Tests
- Price calculation accuracy
- Validation rules
- Enum values
- Edge cases (zero weight, negative values)

### Integration Tests
- API endpoint responses
- Order creation with weight
- Price updates in cart

### System Tests
- Complete ordering flow
- Admin interface usability
- Kitchen display accuracy

## Performance Considerations
- Price calculations should be cached for frequent weights
- Database indexes on new fields
- Efficient queries for weight-based items filtering

## Security Considerations
- Input validation for weight values
- Price manipulation prevention
- Audit trail for weight adjustments

## Dependencies
- No external dependencies required
- Compatible with existing pricing system
- Works with current order flow
