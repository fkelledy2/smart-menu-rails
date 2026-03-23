# Bulk Employee Invitation System

## Overview
Implement a bulk invitation system allowing restaurant managers to invite multiple employees simultaneously via CSV upload or manual entry, with role assignment, onboarding workflows, and invitation tracking.

## Business Value
- **Efficiency**: Saves time when onboarding multiple employees
- **Scalability**: Supports rapid restaurant expansion and seasonal hiring
- **Consistency**: Standardized invitation process for all employees
- **Tracking**: Monitor invitation status and follow up on pending invites

## User Stories

### Restaurant Manager
- As a restaurant manager, I want to invite multiple employees at once using a CSV file so I can quickly onboard new team members
- As a restaurant manager, I want to set roles and departments for each employee during invitation
- As a restaurant manager, I want to track which invitations have been accepted and follow up on pending ones
- As a restaurant manager, I want to resend invitations to employees who haven't responded

### HR Coordinator
- As an HR coordinator, I want to use templates for common employee roles so I can quickly populate invitation data
- As a restaurant manager, I want to preview invitations before sending to catch any errors
- As an HR coordinator, I want to schedule invitations to be sent at specific times

### Employee
- As an invited employee, I want to receive a clear invitation email with instructions
- As an invited employee, I want to easily set up my account and understand my role
- As an invited employee, I want to receive reminders if I haven't accepted the invitation

### System Administrator
- As a system admin, I want to monitor bulk invitation usage across the platform
- As a system admin, I want to set limits on invitation volumes to prevent abuse
- As a system admin, I want to analyze invitation conversion rates

## Technical Requirements

### Data Model Changes

#### BulkInvitation Model (New)
```ruby
create_table :bulk_invitations do |t|
  t.references :restaurant, null: false, foreign_key: true
  t.references :created_by, foreign_key: { to_table: :users }
  t.string :title, null: false
  t.text :description
  t.string :status, default: 'draft'  # draft, sending, sent, completed, failed
  t.integer :total_invitations, default: 0
  t.integer :sent_invitations, default: 0
  t.integer :accepted_invitations, default: 0
  t.datetime :scheduled_for
  t.datetime :sent_at
  t.timestamps
  
  t.index :restaurant_id
  t.index :status
  t.index :created_by_id
end
```

#### BulkInvitationItem Model (New)
```ruby
create_table :bulk_invitation_items do |t|
  t.references :bulk_invitation, null: false, foreign_key: true
  t.string :first_name, null: false
  t.string :last_name, null: false
  t.string :email, null: false
  t.string :phone
  t.string :role, default: 'staff'
  t.string :department
  t.text :notes
  t.string :status, default: 'pending'  # pending, sent, accepted, expired, failed
  t.references :user, foreign_key: true  # When invitation is accepted
  t.references :staff_invitation, foreign_key: true
  t.datetime :sent_at
  t.datetime :accepted_at
  t.text :error_message
  t.timestamps
  
  t.index :bulk_invitation_id
  t.index :email
  t.index :status
  t.index :user_id
end
```

#### StaffInvitation Model Enhancements
```ruby
# Add reference to bulk invitation
add_reference :staff_invitations, :bulk_invitation_item, foreign_key: true
add_column :staff_invitations, :bulk_invitation_status, :string, default: 'individual'
```

### CSV Import Format

#### Standard Template
```csv
first_name,last_name,email,phone,role,department,notes
John,Doe,john.doe@restaurant.com,+1234567890,staff,Front of House,Experienced waiter
Jane,Smith,jane.smith@restaurant.com,,manager,Kitchen,Previous management experience
Mike,Johnson,mike.j@restaurant.com,+1234567891,staff,Bar,Bartender certification
```

#### Validation Rules
- Required fields: first_name, last_name, email
- Email format validation
- Phone number format validation (if provided)
- Role must be valid (staff, manager, admin)
- Department must exist in restaurant
- No duplicate emails within same batch

### API Changes

#### Bulk Invitation Endpoints
```ruby
# POST /api/v1/restaurants/:restaurant_id/bulk_invitations
{
  "title": "Summer 2024 Hiring",
  "description": "Seasonal staff for peak season",
  "scheduled_for": "2024-06-01T09:00:00Z",
  "items": [
    {
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      "phone": "+1234567890",
      "role": "staff",
      "department": "Front of House"
    }
  ]
}

# POST /api/v1/restaurants/:restaurant_id/bulk_invitations/upload
# Content-Type: multipart/form-data
# File: CSV file

# GET /api/v1/restaurants/:restaurant_id/bulk_invitations
# Response: List of bulk invitations with status

# GET /api/v1/bulk_invitations/:id
# Response: Detailed invitation with items

# POST /api/v1/bulk_invitations/:id/send
# Send all pending invitations

# POST /api/v1/bulk_invitations/:id/resend
# Resend failed or expired invitations

# GET /api/v1/bulk_invitations/:id/stats
# Response: Invitation statistics and conversion rates
```

#### Template Endpoints
```ruby
# GET /api/v1/restaurants/:restaurant_id/bulk_invitation_template
# Response: CSV template with restaurant-specific departments

# GET /api/v1/restaurants/:restaurant_id/role_templates
# Response: Predefined role templates
```

### UI/UX Requirements

#### Bulk Invitation Creation
- CSV upload with drag-and-drop
- Manual entry form with add/remove rows
- Template download
- Real-time validation
- Preview before sending

#### Invitation Management Dashboard
- Status overview (sent, accepted, pending)
- Individual invitation management
- Bulk actions (resend, cancel)
- Filtering and sorting
- Export capabilities

#### Employee Entry Interface
- Spreadsheet-like editing
- Auto-complete for departments
- Role selection with descriptions
- Duplicate detection
- Progress indicator

#### Tracking & Analytics
- Real-time status updates
- Conversion rate metrics
- Time-to-accept analysis
- Department breakdown
- Historical trends

### Business Logic

#### CSV Processing Service
```ruby
class BulkInvitationCsvService
  def process_csv(file, restaurant)
    require 'csv'
    
    invitations = []
    errors = []
    
    CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
      invitation = build_invitation_from_row(row, restaurant)
      
      if invitation.valid?
        invitations << invitation
      else
        errors << {
          row: row.line_number,
          errors: invitation.errors.full_messages
        }
      end
    end
    
    { invitations: invitations, errors: errors }
  end
  
  private
  
  def build_invitation_from_row(row, restaurant)
    BulkInvitationItem.new(
      first_name: row[:first_name],
      last_name: row[:last_name],
      email: row[:email],
      phone: row[:phone],
      role: row[:role] || 'staff',
      department: row[:department],
      notes: row[:notes]
    )
  end
end
```

#### Invitation Sending Service
```ruby
class BulkInvitationSender
  def send_invitations(bulk_invitation)
    bulk_invitation.update!(status: 'sending')
    
    bulk_invitation.items.pending.each do |item|
      begin
        send_single_invitation(item)
        item.update!(status: 'sent', sent_at: Time.current)
        bulk_invitation.increment!(:sent_invitations)
      rescue => e
        item.update!(status: 'failed', error_message: e.message)
      end
    end
    
    bulk_invitation.update!(
      status: bulk_invitation.items.failed.any? ? 'completed_with_errors' : 'sent',
      sent_at: Time.current
    )
  end
  
  private
  
  def send_single_invitation(item)
    staff_invitation = StaffInvitation.create!(
      email: item.email,
      restaurant: item.bulk_invitation.restaurant,
      role: item.role,
      first_name: item.first_name,
      last_name: item.last_name,
      phone: item.phone,
      department: item.department,
      message: generate_invitation_message(item),
      bulk_invitation_item: item
    )
    
    item.update!(staff_invitation: staff_invitation)
    StaffInvitationMailer.invitation(staff_invitation).deliver_later
  end
end
```

#### Validation Service
```ruby
class BulkInvitationValidator
  def validate_batch(items, restaurant)
    errors = []
    emails = []
    
    items.each_with_index do |item, index|
      item_errors = validate_single_item(item, restaurant)
      
      # Check for duplicate emails
      if emails.include?(item.email.downcase)
        item_errors << "Email already used in this batch"
      else
        emails << item.email.downcase
      end
      
      # Check for existing users
      if User.exists?(email: item.email)
        item_errors << "User with this email already exists"
      end
      
      errors << { row: index + 1, errors: item_errors } if item_errors.any?
    end
    
    errors
  end
  
  private
  
  def validate_single_item(item, restaurant)
    errors = []
    
    errors << "First name is required" if item.first_name.blank?
    errors << "Last name is required" if item.last_name.blank?
    errors << "Email is required" if item.email.blank?
    errors << "Invalid email format" unless item.email.match?(/\A[^@\s]+@[^@\s]+\z/)
    errors << "Invalid role" unless %w[staff manager admin].include?(item.role)
    
    if item.department.present? && !restaurant.departments.include?(item.department)
      errors << "Invalid department for this restaurant"
    end
    
    errors
  end
end
```

### Implementation Phases

#### Phase 1: Core Infrastructure
1. Database migrations
2. Basic CSV processing
3. Invitation creation workflow
4. Simple sending mechanism

#### Phase 2: User Interface
1. CSV upload interface
2. Manual entry forms
3. Validation and preview
4. Basic dashboard

#### Phase 3: Advanced Features
1. Scheduled sending
2. Template system
3. Analytics dashboard
4. Bulk operations

#### Phase 4: Optimization
1. Performance improvements
2. Error handling
3. Reporting capabilities
4. Integration enhancements

### Testing Requirements

#### Unit Tests
- CSV parsing logic
- Validation rules
- Invitation creation
- Email generation

#### Integration Tests
- File upload handling
- Database transactions
- Email delivery
- Status updates

#### System Tests
- Complete invitation workflows
- Large file handling
- Error scenarios
- UI interactions

### Performance Considerations
- Streaming CSV processing for large files
- Background job processing for email sending
- Efficient database queries
- Progress tracking for long operations

### Security Considerations
- File type validation
- CSV injection prevention
- Rate limiting for invitations
- Email verification requirements

### Dependencies
- CSV parsing library (Ruby's built-in CSV)
- Background job processing (Sidekiq)
- File storage (Active Storage)
- Email delivery (Action Mailer)

### Rollout Strategy
1. Internal testing with small batches
2. Beta with select restaurants
3. Gradual rollout with monitoring
4. Documentation and training materials
5. Performance optimization based on usage
