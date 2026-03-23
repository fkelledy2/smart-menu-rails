# Strikepay Integration for Direct Tips

## Overview
Integrate Strikepay to enable restaurant staff to receive tips directly from customers, independent of the restaurant bill processing. This allows staff to receive tips immediately and directly to their personal accounts.

## Business Value
- **Staff Satisfaction**: Immediate tip receipt improves employee morale
- **Financial Inclusion**: Direct access to tips without waiting for payroll
- **Transparency**: Clear separation between restaurant revenue and staff tips
- **Modern Payment**: Meets customer expectations for digital tipping options

## User Stories

### Restaurant Staff
- As a server, I want to receive tips directly to my Strikepay account so I get my earnings immediately
- As a bartender, I want to display a QR code for customers to tip me directly
- As a kitchen staff, I want to receive tips that customers add for food preparation
- As a staff member, I want to track my tip earnings in real-time

### Customer
- As a customer, I want to tip individual staff members directly so I know they receive the full amount
- As a customer, I want to tip easily using QR codes or mobile payment
- As a customer, I want to see suggested tip amounts and calculate percentages
- As a customer, I want to receive digital receipts for my tips

### Restaurant Manager
- As a restaurant manager, I want to track staff tips for reporting and compliance
- As a restaurant manager, I want to ensure tip distribution is fair and transparent
- As a restaurant manager, I want to monitor tip trends and staff performance
- As a restaurant manager, I want to export tip reports for accounting

### System Administrator
- As a system admin, I want to monitor Strikepay API usage and errors
- As a system admin, I want to reconcile tip transactions with financial records
- As a system admin, I want to manage Strikepay account configurations

## Technical Requirements

### Data Model Changes

#### StrikepayAccount Model (New)
```ruby
create_table :strikepay_accounts do |t|
  t.references :user, null: false, foreign_key: true
  t.references :restaurant, null: false, foreign_key: true
  t.string :strikepay_user_id, null: false
  t.string :strikepay_account_id, null: false
  t.string :display_name, null: false
  t.string :qr_code_url
  t.boolean :active, default: true
  t.decimal :total_tips_received, default: 0, precision: 12, scale: 2
  t.integer :tip_count, default: 0
  t.datetime :last_tip_at
  t.timestamps
  
  t.index [:user_id, :restaurant_id], unique: true
  t.index :strikepay_user_id
  t.index :active
end
```

#### DirectTip Model (New)
```ruby
create_table :direct_tips do |t|
  t.references :strikepay_account, null: false, foreign_key: true
  t.references :ordr, foreign_key: true  # Optional - associated order if any
  t.references :tablesetting, foreign_key: true  # Table where tip was given
  t.decimal :amount, null: false, precision: 10, scale: 2
  t.string :currency, default: 'USD'
  t.string :customer_name
  t.string :customer_email
  t.string :stripe_payment_intent_id  # Stripe transaction ID
  t.string :strikepay_transaction_id
  t.string :status, default: 'pending'  # pending, completed, failed, refunded
  t.decimal :fee_amount, precision: 10, scale: 2
  t.decimal :net_amount, precision: 10, scale: 2
  t.text :notes
  t.datetime :processed_at
  t.timestamps
  
  t.index :strikepay_account_id
  t.index :ordr_id
  t.index :status
  t.index :created_at
end
```

#### TipPool Model (New)
```ruby
create_table :tip_pools do |t|
  t.references :restaurant, null: false, foreign_key: true
  t.string :name, null: false
  t.text :description
  t.boolean :active, default: true
  t.decimal :total_amount, default: 0, precision: 12, scale: 2
  t.date :pool_date
  t.timestamps
  
  t.index :restaurant_id
  t.index :active
end

create_table :tip_pool_participants do |t|
  t.references :tip_pool, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.decimal :share_percentage, precision: 5, scale: 2
  t.decimal :total_received, default: 0, precision: 12, scale: 2
  t.timestamps
  
  t.index [:tip_pool_id, :user_id], unique: true
end
```

#### User Model Enhancements
```ruby
add_column :users, :strikepay_enabled, :boolean, default: false
add_column :users, :preferred_tip_method, :string, default: 'direct'  # direct, pool, traditional
```

### Strikepay API Integration

#### Authentication & Setup
```ruby
# app/services/strikepay_service.rb
class StrikepayService
  BASE_URL = 'https://api.strikepay.com/v1'
  
  def initialize(restaurant)
    @restaurant = restaurant
    @api_key = restaurant.strikepay_api_key
    @api_secret = restaurant.strikepay_api_secret
  end
  
  def create_account(user)
    response = make_request(:post, '/accounts', {
      email: user.email,
      name: user.full_name,
      business_name: @restaurant.name
    })
    
    if response.success?
      StrikepayAccount.create!(
        user: user,
        restaurant: @restaurant,
        strikepay_user_id: response['user_id'],
        strikepay_account_id: response['account_id'],
        display_name: user.full_name,
        qr_code_url: response['qr_code_url']
      )
    else
      raise Error, "Failed to create Strikepay account: #{response['message']}"
    end
  end
  
  def generate_payment_qr(account, amount_cents)
    response = make_request(:post, '/payments/qrcode', {
      account_id: account.strikepay_account_id,
      amount_cents: amount_cents,
      currency: 'USD',
      description: "Tip for #{account.display_name}"
    })
    
    response['qr_code_url']
  end
  
  def process_payment(payment_intent_id)
    response = make_request(:post, '/payments/confirm', {
      payment_intent_id: payment_intent_id
    })
    
    response
  end
  
  private
  
  def make_request(method, endpoint, params = {})
    # Implementation for Strikepay API calls
    # Include authentication, error handling, etc.
  end
end
```

### API Changes

#### Strikepay Endpoints
```ruby
# POST /api/v1/strikepay/setup
{
  "user_id": 123,
  "accept_terms": true
}

# GET /api/v1/strikepay/accounts/:id
{
  "id": 456,
  "user_id": 123,
  "display_name": "John Doe",
  "qr_code_url": "https://strikepay.com/qr/abc123",
  "total_tips_received": 1250.50,
  "tip_count": 45,
  "active": true
}

# POST /api/v1/strikepay/generate_qr
{
  "account_id": 456,
  "amount_cents": 500,  # $5.00
  "order_id": 789  # Optional
}

# GET /api/v1/strikepay/tips
# Query parameters: start_date, end_date, user_id
{
  "tips": [
    {
      "id": 1001,
      "amount": 5.00,
      "currency": "USD",
      "customer_name": "Jane Smith",
      "created_at": "2024-01-15T14:30:00Z",
      "status": "completed"
    }
  ],
  "total_amount": 1250.50,
  "count": 45
}

# POST /api/v1/strikepay/tips/:id/refund
{
  "reason": "Customer request"
}
```

#### Staff Management Endpoints
```ruby
# GET /api/v1/restaurants/:restaurant_id/staff_strikepay
{
  "staff": [
    {
      "user_id": 123,
      "name": "John Doe",
      "role": "server",
      "strikepay_enabled": true,
      "qr_code_url": "https://strikepay.com/qr/abc123",
      "today_tips": 45.00,
      "week_tips": 320.50
    }
  ]
}
```

### UI/UX Requirements

#### Staff Tip Interface
- Personal QR code display
- Real-time tip notifications
- Tip history and analytics
- Payout settings
- Tip pool participation options

#### Customer Tipping Interface
- Staff selection (by name/photo)
- Amount input with suggestions
- Payment method selection
- Digital receipt option
- Anonymous tipping option

#### Restaurant Management Dashboard
- Staff tip tracking
- Tip pool management
- Analytics and reporting
- Payout reconciliation
- Compliance reporting

#### QR Code Display
- Table-mounted QR codes
- Staff badge QR codes
- Digital display integration
- Custom branding options

### Frontend Implementation

#### React Components
```jsx
// components/TipModal.jsx
const TipModal = ({ staff, order, onClose }) => {
  const [amount, setAmount] = useState('');
  const [loading, setLoading] = useState(false);
  
  const handleTip = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/v1/strikepay/process_tip', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          staff_id: staff.id,
          amount_cents: amount * 100,
          order_id: order?.id
        })
      });
      
      if (response.ok) {
        // Show success message
        onClose();
      }
    } catch (error) {
      // Handle error
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <Modal>
      <div className="tip-modal">
        <h3>Tip {staff.name}</h3>
        <AmountInput value={amount} onChange={setAmount} />
        <SuggestedAmounts onSelect={setAmount} />
        <PaymentOptions />
        <button onClick={handleTip} disabled={loading}>
          Send Tip
        </button>
      </div>
    </Modal>
  );
};

// components/StaffQRDisplay.jsx
const StaffQRDisplay = ({ staff }) => {
  return (
    <div className="staff-qr-display">
      <img src={staff.qr_code_url} alt="Tip QR Code" />
      <p>Scan to tip {staff.name}</p>
      <AmountButtons staffId={staff.id} />
    </div>
  );
};
```

### Business Logic

#### Tip Processing Service
```ruby
class DirectTipService
  def self.create_tip(staff_account, amount_cents, customer_info = {})
    ActiveRecord::Base.transaction do
      # Calculate fees (Strikepay typically charges 2.9% + $0.30)
      fee_amount = calculate_fees(amount_cents)
      net_amount = amount_cents - fee_amount
      
      tip = DirectTip.create!(
        strikepay_account: staff_account,
        amount: amount_cents / 100.0,
        currency: 'USD',
        customer_name: customer_info[:name],
        customer_email: customer_info[:email],
        fee_amount: fee_amount / 100.0,
        net_amount: net_amount / 100.0
      )
      
      # Update staff account totals
      staff_account.update!(
        total_tips_received: staff_account.total_tips_received + (net_amount / 100.0),
        tip_count: staff_account.tip_count + 1,
        last_tip_at: Time.current
      )
      
      # Process payment through Strikepay
      process_strikepay_payment(tip)
      
      tip
    end
  end
  
  private
  
  def self.calculate_fees(amount_cents)
    # Strikepay fee structure: 2.9% + $0.30
    (amount_cents * 0.029) + 30
  end
  
  def self.process_strikepay_payment(tip)
    # Integration with Strikepay API
    # This would handle the actual payment processing
  end
end
```

#### Tip Pool Distribution
```ruby
class TipPoolService
  def self.distribute_to_pool(tip, pool)
    participants = pool.tip_pool_participants
    
    participants.each do |participant|
      share_amount = tip.net_amount * (participant.share_percentage / 100.0)
      
      # Create individual tip records for each participant
      DirectTip.create!(
        strikepay_account: participant.user.strikepay_accounts.first,
        amount: share_amount,
        currency: tip.currency,
        status: 'completed',
        processed_at: Time.current,
        notes: "From tip pool: #{pool.name}"
      )
    end
  end
end
```

### Implementation Phases

#### Phase 1: Core Integration
1. Strikepay API integration
2. Account creation and management
3. Basic QR code generation
4. Simple tip processing

#### Phase 2: User Interface
1. Staff tip dashboard
2. Customer tipping interface
3. QR code displays
4. Basic analytics

#### Phase 3: Advanced Features
1. Tip pools and sharing
2. Advanced analytics
3. Mobile app integration
4. Payout automation

#### Phase 4: Optimization
1. Performance improvements
2. Enhanced security
3. Compliance features
4. Reporting tools

### Testing Requirements

#### Unit Tests
- Strikepay API integration
- Tip calculation logic
- Fee processing
- Account management

#### Integration Tests
- Payment processing flow
- Database transactions
- API endpoint responses
- Error handling

#### System Tests
- Complete tipping workflows
- QR code functionality
- Mobile responsiveness
- Multi-user scenarios

### Security Considerations

#### Payment Security
- PCI compliance for payment processing
- Secure API key management
- Encrypted sensitive data
- Audit trails for all transactions

#### Data Privacy
- Customer information protection
- Staff privacy controls
- GDPR compliance
- Data retention policies

#### Fraud Prevention
- Transaction monitoring
- Amount limits
- Velocity controls
- Suspicious activity detection

### Compliance Requirements

#### Financial Regulations
- Payment processing regulations
- Money transmission compliance
- Tax reporting requirements
- Anti-money laundering (AML) checks

#### Employment Law
- Tip credit compliance
- Minimum wage implications
- Tip pooling regulations
- Staff classification rules

### Performance Considerations
- Real-time tip notifications
- Efficient payment processing
- Scalable QR code generation
- Optimized database queries

### Dependencies
- Strikepay API access
- Stripe integration for payments
- Redis for real-time notifications
- Image storage for QR codes

### Cost Analysis
- Strikepay processing fees: ~2.9% + $0.30 per transaction
- Development and implementation costs
- Ongoing maintenance and support
- Compliance and legal costs

### Rollout Strategy
1. Pilot program with select restaurants
2. Staff training and onboarding
3. Customer education and marketing
4. Gradual rollout with monitoring
5. Continuous optimization based on feedback
