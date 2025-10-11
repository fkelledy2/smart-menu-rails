# Mellow Admin JWT Token Management Feature Request

## 📋 **Feature Overview**

**Feature Name**: Mellow Admin JWT Access Token Management System
**Priority**: High
**Category**: Authentication & Authorization
**Estimated Effort**: Large (8-12 weeks)
**Target Release**: Q1 2026

## 🎯 **User Story**

**As a** mellow menu admin user (someone who has an @mellow.menu email address)
**I want to** be able to configure and send a JWT access token to a restaurant manager
**So that** the restaurant can access mellow.menu via the exposed SWAGGER-based REST APIs

## 📖 **Detailed Requirements**

### **Primary Requirements**

#### **1. Admin User Authentication & Authorization**
- **Admin User Identification**: System must identify users with @mellow.menu email addresses as admin users
- **Admin Dashboard Access**: Dedicated admin interface for JWT token management
- **Role-Based Permissions**: Admin-specific permissions for token generation and management
- **Audit Trail**: Complete logging of all admin actions related to token management

#### **2. JWT Token Configuration System**
- **Token Generation**: Ability to generate secure JWT tokens for restaurant access
- **Token Customization**: Configure token expiration, scopes, and permissions per restaurant
- **Token Metadata**: Associate tokens with specific restaurants, managers, and access levels
- **Token Revocation**: Ability to immediately revoke tokens when needed

#### **3. Restaurant Manager Token Delivery**
- **Secure Token Transmission**: Send tokens via secure email or secure download link
- **Token Instructions**: Include comprehensive documentation on API usage
- **Integration Guides**: Provide SWAGGER documentation and code examples
- **Support Contact**: Include support channels for technical assistance

#### **4. API Access Management**
- **Scoped Access**: Tokens provide access only to restaurant-specific data
- **Rate Limiting**: Implement appropriate rate limits for API access
- **Usage Monitoring**: Track API usage per token/restaurant
- **Security Monitoring**: Monitor for suspicious activity or misuse

### **Secondary Requirements**

#### **5. Token Lifecycle Management**
- **Token Renewal**: System for renewing expiring tokens
- **Automatic Notifications**: Alert admins and restaurants of upcoming expirations
- **Token History**: Maintain history of all tokens issued to each restaurant
- **Bulk Operations**: Ability to manage multiple tokens simultaneously

#### **6. API Documentation Integration**
- **Dynamic SWAGGER Docs**: Generate restaurant-specific API documentation
- **Interactive Testing**: Allow restaurants to test APIs directly from documentation
- **Code Examples**: Provide examples in multiple programming languages
- **Postman Collections**: Generate Postman collections for easy API testing

## 🔧 **Technical Specifications**

### **Backend Implementation**

#### **1. Database Schema**
```sql
-- Admin JWT Tokens table
CREATE TABLE admin_jwt_tokens (
  id BIGINT PRIMARY KEY,
  admin_user_id BIGINT NOT NULL,
  restaurant_id BIGINT NOT NULL,
  token_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  scopes JSON NOT NULL,
  expires_at TIMESTAMP,
  revoked_at TIMESTAMP,
  last_used_at TIMESTAMP,
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  FOREIGN KEY (admin_user_id) REFERENCES users(id),
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
  INDEX idx_token_hash (token_hash),
  INDEX idx_restaurant_id (restaurant_id),
  INDEX idx_admin_user_id (admin_user_id)
);

-- Token usage logs
CREATE TABLE jwt_token_usage_logs (
  id BIGINT PRIMARY KEY,
  jwt_token_id BIGINT NOT NULL,
  endpoint VARCHAR(255) NOT NULL,
  method VARCHAR(10) NOT NULL,
  ip_address INET,
  user_agent TEXT,
  response_status INTEGER,
  created_at TIMESTAMP NOT NULL,

  FOREIGN KEY (jwt_token_id) REFERENCES admin_jwt_tokens(id),
  INDEX idx_jwt_token_id (jwt_token_id),
  INDEX idx_created_at (created_at)
);
```

#### **2. JWT Token Structure**
```json
{
  "iss": "mellow.menu",
  "sub": "restaurant_api_access",
  "aud": "api.mellow.menu",
  "exp": 1735689600,
  "iat": 1704153600,
  "jti": "unique-token-id",
  "restaurant_id": 123,
  "admin_user_id": 456,
  "scopes": [
    "menu:read",
    "menu:write",
    "orders:read",
    "analytics:read"
  ],
  "rate_limit": {
    "requests_per_minute": 100,
    "requests_per_hour": 1000
  }
}
```

#### **3. API Scopes Definition**
```ruby
class ApiScope
  AVAILABLE_SCOPES = {
    'menu:read' => 'Read menu data',
    'menu:write' => 'Create and update menu items',
    'orders:read' => 'Read order data',
    'orders:write' => 'Update order status',
    'analytics:read' => 'Access analytics data',
    'customers:read' => 'Read customer data',
    'settings:read' => 'Read restaurant settings',
    'settings:write' => 'Update restaurant settings'
  }.freeze
end
```

### **Frontend Implementation**

#### **1. Admin Dashboard Components**
- **Token Management Interface**: List, create, edit, and revoke tokens
- **Restaurant Selection**: Search and select restaurants for token assignment
- **Scope Configuration**: Visual interface for selecting API permissions
- **Usage Analytics**: Dashboard showing token usage statistics
- **Security Monitoring**: Alerts and logs for suspicious activity

#### **2. Token Delivery Interface**
- **Email Composition**: Rich text editor for sending token instructions
- **Template System**: Pre-built email templates for different scenarios
- **Secure Download**: Generate secure, time-limited download links
- **Documentation Generator**: Auto-generate API documentation for each token

## 🔐 **Security Considerations**

### **1. Token Security**
- **Secure Generation**: Use cryptographically secure random generation
- **Token Hashing**: Store only hashed versions of tokens in database
- **Transmission Security**: Use HTTPS and encrypted email for token delivery
- **Token Rotation**: Implement regular token rotation policies

### **2. Access Control**
- **Admin Verification**: Strict verification of @mellow.menu email addresses
- **Multi-Factor Authentication**: Require MFA for admin users
- **IP Restrictions**: Optional IP whitelisting for token usage
- **Audit Logging**: Comprehensive logging of all admin and API actions

### **3. Rate Limiting & Monitoring**
- **API Rate Limits**: Configurable rate limits per token
- **Anomaly Detection**: Monitor for unusual usage patterns
- **Automatic Revocation**: Auto-revoke tokens showing suspicious activity
- **Security Alerts**: Real-time alerts for security events

## 🎨 **User Interface Design**

### **1. Admin Dashboard**
```
┌─────────────────────────────────────────────────────────────┐
│ Mellow Menu Admin - JWT Token Management                    │
├─────────────────────────────────────────────────────────────┤
│ [+ New Token] [Bulk Actions ▼] [Export] [Settings]         │
├─────────────────────────────────────────────────────────────┤
│ Search: [________________] Filter: [All ▼] [Active ▼]       │
├─────────────────────────────────────────────────────────────┤
│ Restaurant Name    │ Token Name     │ Status │ Expires │ ⚙️  │
│ Pizza Palace       │ API Access     │ Active │ 30 days │ ⚙️  │
│ Burger Barn        │ Menu Sync      │ Active │ 60 days │ ⚙️  │
│ Sushi Station      │ Order Mgmt     │ Revoked│ Expired │ ⚙️  │
└─────────────────────────────────────────────────────────────┘
```

### **2. Token Creation Form**
```
┌─────────────────────────────────────────────────────────────┐
│ Create New JWT Token                                        │
├─────────────────────────────────────────────────────────────┤
│ Restaurant: [Search restaurants...                      ▼] │
│ Token Name: [_________________________________]             │
│ Description: [_________________________________]            │
│                                                             │
│ Permissions:                                                │
│ ☑️ Menu Management    ☑️ Order Access                       │
│ ☑️ Analytics          ☐ Customer Data                      │
│ ☐ Settings            ☐ Advanced Features                  │
│                                                             │
│ Expiration: [90 days ▼] Custom: [___________]              │
│ Rate Limit: [100 req/min ▼] [1000 req/hour ▼]             │
│                                                             │
│ Delivery Method:                                            │
│ ○ Email to restaurant manager                               │
│ ○ Secure download link                                      │
│ ○ Display token (copy manually)                             │
│                                                             │
│ [Cancel] [Create Token]                                     │
└─────────────────────────────────────────────────────────────┘
```

## 📊 **API Endpoints**

### **1. Admin Token Management APIs**
```ruby
# Admin JWT Token Management
POST   /admin/api/jwt_tokens              # Create new token
GET    /admin/api/jwt_tokens              # List all tokens
GET    /admin/api/jwt_tokens/:id          # Get token details
PATCH  /admin/api/jwt_tokens/:id          # Update token
DELETE /admin/api/jwt_tokens/:id          # Revoke token
POST   /admin/api/jwt_tokens/:id/renew    # Renew token
GET    /admin/api/jwt_tokens/:id/usage    # Get usage statistics

# Token delivery
POST   /admin/api/jwt_tokens/:id/send_email    # Send token via email
POST   /admin/api/jwt_tokens/:id/download_link # Generate download link
```

### **2. Restaurant API Endpoints (JWT Protected)**
```ruby
# Menu Management
GET    /api/v1/restaurants/:id/menus
POST   /api/v1/restaurants/:id/menus
GET    /api/v1/restaurants/:id/menus/:menu_id
PATCH  /api/v1/restaurants/:id/menus/:menu_id
DELETE /api/v1/restaurants/:id/menus/:menu_id

# Order Management
GET    /api/v1/restaurants/:id/orders
GET    /api/v1/restaurants/:id/orders/:order_id
PATCH  /api/v1/restaurants/:id/orders/:order_id/status

# Analytics
GET    /api/v1/restaurants/:id/analytics/dashboard
GET    /api/v1/restaurants/:id/analytics/orders
GET    /api/v1/restaurants/:id/analytics/menu_performance
```

## 🧪 **Testing Strategy**

### **1. Unit Tests**
- JWT token generation and validation
- Scope-based authorization
- Token lifecycle management
- Rate limiting functionality

### **2. Integration Tests**
- Admin dashboard workflows
- Token delivery mechanisms
- API access with JWT tokens
- Security and audit logging

### **3. Security Tests**
- Token tampering attempts
- Unauthorized access attempts
- Rate limit enforcement
- Audit trail verification

## 📈 **Success Metrics**

### **1. Adoption Metrics**
- Number of restaurants using JWT tokens
- API usage growth over time
- Token renewal rates
- Support ticket reduction

### **2. Security Metrics**
- Zero security incidents
- Successful audit compliance
- Token misuse detection rate
- Admin user satisfaction

### **3. Performance Metrics**
- API response times
- Token validation performance
- Dashboard load times
- System uptime

## 🚀 **Implementation Roadmap**

### **Phase 1: Foundation (Weeks 1-3)**
- Database schema implementation
- JWT token generation system
- Basic admin authentication
- Core API endpoints

### **Phase 2: Admin Interface (Weeks 4-6)**
- Admin dashboard development
- Token management interface
- Restaurant selection system
- Basic token delivery

### **Phase 3: API Integration (Weeks 7-9)**
- SWAGGER documentation generation
- API scope enforcement
- Rate limiting implementation
- Usage monitoring

### **Phase 4: Security & Polish (Weeks 10-12)**
- Security audit and testing
- Performance optimization
- Documentation completion
- User training materials

## 🔗 **Dependencies**

### **Technical Dependencies**
- JWT library (ruby-jwt gem)
- Admin authentication system
- SWAGGER documentation framework
- Email delivery system
- Rate limiting infrastructure

### **Business Dependencies**
- Admin user role definition
- Restaurant onboarding process
- API documentation standards
- Security compliance requirements

## 📚 **Documentation Requirements**

### **1. Admin Documentation**
- JWT token management guide
- Security best practices
- Troubleshooting guide
- API scope reference

### **2. Restaurant Documentation**
- API integration guide
- SWAGGER documentation
- Code examples and SDKs
- Support and contact information

### **3. Developer Documentation**
- Technical architecture
- Security implementation
- Testing procedures
- Deployment guide

## 🎯 **Acceptance Criteria**

### **Must Have**
- ✅ Admin users can generate JWT tokens for restaurants
- ✅ Tokens provide scoped access to restaurant APIs
- ✅ Secure token delivery via email or download
- ✅ Token revocation and lifecycle management
- ✅ Comprehensive audit logging
- ✅ Rate limiting and security monitoring

### **Should Have**
- ✅ Interactive SWAGGER documentation
- ✅ Usage analytics and monitoring
- ✅ Bulk token management operations
- ✅ Automated token renewal notifications
- ✅ Multi-language code examples

### **Could Have**
- ✅ Advanced security features (IP restrictions)
- ✅ Custom token templates
- ✅ Integration with external monitoring tools
- ✅ Advanced analytics and reporting

## 📞 **Stakeholders**

### **Primary Stakeholders**
- **Mellow Menu Admin Team**: Primary users of the system
- **Restaurant Managers**: Recipients and users of JWT tokens
- **Development Team**: Implementation and maintenance
- **Security Team**: Security review and compliance

### **Secondary Stakeholders**
- **Customer Support**: Handle token-related inquiries
- **Product Management**: Feature prioritization and roadmap
- **QA Team**: Testing and quality assurance
- **DevOps Team**: Deployment and monitoring

---

**Created**: October 11, 2025
**Last Updated**: October 11, 2025
**Status**: Draft
**Assigned To**: TBD
**Review Date**: TBD
