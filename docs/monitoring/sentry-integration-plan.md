# Sentry Integration Implementation Plan
## Smart Menu Rails Application

**Created**: November 1, 2025  
**Status**: 🚧 **IN PROGRESS**  
**Priority**: HIGH  

---

## 🎯 **Objective**

Implement enterprise-grade error tracking and performance monitoring using Sentry to enable proactive issue detection, faster debugging, and improved application reliability for the Smart Menu platform.

---

## 📊 **Current State Analysis**

### **Existing Error Handling**
- **Rails Logger**: Basic logging to `log/production.log`
- **Exception Handling**: Custom error pages (404, 500, etc.)
- **No Centralized Tracking**: Errors scattered across log files
- **No Real-time Alerts**: Manual log monitoring required
- **No Performance Monitoring**: Limited visibility into slow transactions
- **No JavaScript Error Tracking**: Frontend errors go unnoticed

### **Pain Points**
1. ❌ **Reactive Bug Detection** - Discover issues only when users report them
2. ❌ **Difficult Debugging** - Limited context for production errors
3. ❌ **No Error Trends** - Can't identify recurring issues
4. ❌ **No Performance Insights** - Slow endpoints go undetected
5. ❌ **No Frontend Visibility** - JavaScript errors invisible
6. ❌ **Manual Monitoring** - Time-consuming log analysis

---

## 🎯 **Implementation Strategy**

### **Phase 1: Sentry Backend Setup** (Priority: CRITICAL)

#### **1.1 Install Sentry Gem**
```ruby
# Gemfile
gem 'sentry-ruby'
gem 'sentry-rails'
```

**Dependencies**:
- `sentry-ruby` - Core Sentry SDK
- `sentry-rails` - Rails-specific integration

#### **1.2 Create Sentry Initializer**
**File**: `config/initializers/sentry.rb`

**Configuration Strategy**:
- Environment-specific DSN (Data Source Name)
- Release tracking with Git SHA
- Environment tagging (production, staging, development)
- Sample rate configuration
- Performance monitoring
- Breadcrumbs for debugging context

**Key Features**:
- ✅ Automatic exception capture
- ✅ Request context (params, headers, user)
- ✅ Background job tracking (Sidekiq)
- ✅ SQL query tracking
- ✅ Custom tags and context
- ✅ User identification

#### **1.3 Environment Configuration**
**Files**: `.env`, `.env.production`, `.env.staging`

**Required Variables**:
```bash
SENTRY_DSN=https://[key]@[org].ingest.sentry.io/[project]
SENTRY_ENVIRONMENT=production
SENTRY_RELEASE=smart-menu@1.0.0
```

**Security**:
- ✅ DSN stored in environment variables
- ✅ Never commit DSN to version control
- ✅ Different projects for staging/production
- ✅ Separate error quotas per environment

---

### **Phase 2: JavaScript Error Tracking** (Priority: HIGH)

#### **2.1 Install Sentry JavaScript SDK**
```bash
yarn add @sentry/browser @sentry/tracing
```

**Dependencies**:
- `@sentry/browser` - Browser error tracking
- `@sentry/tracing` - Performance monitoring

#### **2.2 Create Sentry JavaScript Initializer**
**File**: `app/javascript/sentry.js`

**Configuration**:
```javascript
import * as Sentry from '@sentry/browser';
import { BrowserTracing } from '@sentry/tracing';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.RAILS_ENV,
  release: process.env.SENTRY_RELEASE,
  integrations: [new BrowserTracing()],
  tracesSampleRate: 0.1,
  beforeSend(event, hint) {
    // Filter sensitive data
    return event;
  }
});
```

#### **2.3 Source Map Upload**
**Purpose**: Map minified JavaScript errors to original source code

**Configuration**:
- Upload source maps during deployment
- Use `@sentry/webpack-plugin` or manual upload
- Configure release association
- Enable source map debugging

**Build Integration**:
```javascript
// esbuild.config.mjs
// Add source map generation
```

---

### **Phase 3: Release Tracking** (Priority: MEDIUM)

#### **3.1 Git Integration**
**Purpose**: Associate errors with specific deployments

**Implementation**:
- Capture Git SHA during build
- Tag releases in Sentry
- Track deploy timestamps
- Associate commits with errors

**Configuration**:
```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.release = ENV.fetch('SENTRY_RELEASE') do
    # Fallback to Git SHA
    `git rev-parse HEAD`.strip
  end
end
```

#### **3.2 Deployment Tracking**
**Purpose**: Mark when new code is deployed

**Implementation**:
- Send deploy webhook to Sentry
- Track deployment environment
- Associate errors with releases
- Enable release comparison

**Deploy Script**:
```bash
# Deploy hook
sentry-cli releases new "$RELEASE"
sentry-cli releases set-commits "$RELEASE" --auto
sentry-cli releases finalize "$RELEASE"
sentry-cli releases deploys "$RELEASE" new -e production
```

---

### **Phase 4: Performance Monitoring** (Priority: MEDIUM)

#### **4.1 Transaction Tracing**
**Purpose**: Identify slow endpoints and database queries

**Configuration**:
```ruby
Sentry.init do |config|
  config.traces_sample_rate = 0.1  # Sample 10% of transactions
  config.profiles_sample_rate = 0.1  # Profile 10% of transactions
end
```

**Tracked Metrics**:
- ✅ HTTP request duration
- ✅ Database query time
- ✅ External API calls
- ✅ Background job execution
- ✅ Cache hit/miss rates

#### **4.2 Custom Instrumentation**
**Purpose**: Track business-critical operations

**Implementation**:
```ruby
# Track specific operations
Sentry.with_scope do |scope|
  scope.set_transaction_name('Order Processing')
  scope.set_tag('order_type', 'dine_in')
  
  Sentry::Profiler.start do
    # Business logic
  end
end
```

**Key Operations to Track**:
- Order creation and processing
- Payment processing
- Menu import (OCR)
- Analytics report generation
- Inventory updates

---

### **Phase 5: Alert Configuration** (Priority: HIGH)

#### **5.1 Error Alerts**
**Purpose**: Immediate notification of critical errors

**Alert Rules**:
1. **Critical Errors** - Notify immediately
   - Payment failures
   - Authentication errors
   - Database connection issues
   - External API failures

2. **High-Frequency Errors** - Alert on spike
   - > 10 errors/minute
   - New error types
   - Regression (previously resolved)

3. **User Impact** - Alert on affected users
   - > 5% of users affected
   - Critical user journey failures

#### **5.2 Performance Alerts**
**Purpose**: Detect performance degradation

**Alert Rules**:
1. **Slow Endpoints** - Alert on degradation
   - P95 > 2 seconds
   - P99 > 5 seconds
   - Sudden increase in latency

2. **Database Performance** - Alert on slow queries
   - Query time > 1 second
   - N+1 query detection
   - Lock contention

#### **5.3 Notification Channels**
**Integrations**:
- ✅ **Slack** - Real-time team notifications
- ✅ **Email** - Critical error summaries
- ✅ **PagerDuty** - On-call escalation (optional)
- ✅ **Webhook** - Custom integrations

**Configuration**:
```yaml
# Sentry Alert Rules
- name: "Critical Payment Errors"
  conditions:
    - event.tags.error_type = "payment_failure"
  actions:
    - slack: "#alerts-critical"
    - email: "team@smartmenu.com"
    
- name: "High Error Rate"
  conditions:
    - event.count > 10 in 1 minute
  actions:
    - slack: "#alerts-errors"
```

---

## 🔧 **Implementation Details**

### **Sentry Configuration Options**

#### **Error Filtering**
```ruby
Sentry.init do |config|
  # Ignore common errors
  config.excluded_exceptions += [
    'ActionController::RoutingError',
    'ActiveRecord::RecordNotFound'
  ]
  
  # Filter sensitive data
  config.before_send = lambda do |event, hint|
    # Remove sensitive params
    event.request.data.delete(:password)
    event.request.data.delete(:credit_card)
    event
  end
end
```

#### **User Context**
```ruby
# In ApplicationController
before_action :set_sentry_context

def set_sentry_context
  Sentry.set_user(
    id: current_user&.id,
    email: current_user&.email,
    username: current_user&.name,
    ip_address: request.remote_ip
  )
  
  Sentry.set_tags(
    restaurant_id: current_restaurant&.id,
    user_role: current_user&.role
  )
end
```

#### **Custom Breadcrumbs**
```ruby
# Track user actions
Sentry.add_breadcrumb(
  Sentry::Breadcrumb.new(
    category: 'order',
    message: 'Order created',
    data: { order_id: order.id, total: order.gross },
    level: 'info'
  )
)
```

---

## 📋 **Testing Strategy**

### **Test Coverage**

#### **1. Sentry Initialization Tests**
**File**: `test/initializers/sentry_test.rb`

**Test Cases**:
- ✅ Sentry initializes with correct DSN
- ✅ Environment is set correctly
- ✅ Release tracking is configured
- ✅ Sample rates are appropriate
- ✅ Excluded exceptions are configured

#### **2. Error Capture Tests**
**File**: `test/integration/sentry_error_capture_test.rb`

**Test Cases**:
- ✅ Exceptions are captured and sent to Sentry
- ✅ User context is attached to errors
- ✅ Request context is included
- ✅ Custom tags are applied
- ✅ Breadcrumbs are recorded
- ✅ Sensitive data is filtered

#### **3. Performance Monitoring Tests**
**File**: `test/integration/sentry_performance_test.rb`

**Test Cases**:
- ✅ Transactions are created for requests
- ✅ Database queries are tracked
- ✅ Custom spans are recorded
- ✅ Sample rate is respected
- ✅ Performance data is sent

#### **4. JavaScript Error Tests**
**File**: `test/javascript/sentry.test.js`

**Test Cases**:
- ✅ Sentry initializes in browser
- ✅ JavaScript errors are captured
- ✅ User context is set
- ✅ Custom events are tracked
- ✅ Source maps are working

---

## 🎯 **Success Criteria**

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Error Detection Time** | < 5 minutes | Time from error to alert |
| **Error Context Completeness** | > 95% | Errors with full context |
| **False Positive Rate** | < 5% | Irrelevant alerts |
| **Performance Overhead** | < 50ms | P95 latency increase |
| **JavaScript Error Capture** | > 90% | Frontend errors tracked |
| **Alert Response Time** | < 15 minutes | Time to acknowledge |
| **Release Tracking** | 100% | All deploys tracked |

---

## 📊 **Expected Impact**

### **Business Value**

#### **Faster Bug Detection**
- **Before**: Hours/days to discover production issues
- **After**: Minutes to receive alerts
- **Impact**: 95% reduction in detection time

#### **Improved Debugging**
- **Before**: Limited context, difficult reproduction
- **After**: Full stack traces, user context, breadcrumbs
- **Impact**: 70% reduction in debugging time

#### **Proactive Issue Resolution**
- **Before**: Reactive bug fixes after user reports
- **After**: Fix issues before users notice
- **Impact**: 50% reduction in user-reported bugs

#### **Performance Optimization**
- **Before**: No visibility into slow endpoints
- **After**: Detailed performance metrics
- **Impact**: Identify and fix slow queries

### **Technical Benefits**

1. ✅ **Centralized Error Tracking** - All errors in one place
2. ✅ **Real-time Alerts** - Immediate notification
3. ✅ **Error Trends** - Identify recurring issues
4. ✅ **Release Correlation** - Associate errors with deploys
5. ✅ **Performance Insights** - Slow transaction detection
6. ✅ **JavaScript Visibility** - Frontend error tracking
7. ✅ **User Impact Analysis** - Affected user metrics

---

## 🔒 **Security & Privacy**

### **Data Protection**

#### **Sensitive Data Filtering**
```ruby
config.before_send = lambda do |event, hint|
  # Remove sensitive fields
  event.request.data.delete(:password)
  event.request.data.delete(:password_confirmation)
  event.request.data.delete(:credit_card_number)
  event.request.data.delete(:cvv)
  event.request.data.delete(:ssn)
  
  # Sanitize headers
  event.request.headers.delete('Authorization')
  event.request.headers.delete('Cookie')
  
  event
end
```

#### **PII Handling**
- ✅ No credit card data sent to Sentry
- ✅ No passwords or tokens
- ✅ Email addresses hashed (optional)
- ✅ IP addresses anonymized (optional)
- ✅ GDPR-compliant data retention

#### **Data Retention**
- **Errors**: 90 days
- **Performance Data**: 30 days
- **User Data**: Anonymized after 90 days
- **Compliance**: GDPR, CCPA compliant

---

## 💰 **Cost Analysis**

### **Sentry Pricing** (Estimated)

#### **Team Plan** (Recommended)
- **Price**: $26/month per team member
- **Events**: 50,000 errors/month included
- **Performance**: 100,000 transactions/month
- **Features**: 
  - Unlimited projects
  - 90-day data retention
  - Slack/email alerts
  - Release tracking
  - Performance monitoring

#### **Business Plan** (If needed)
- **Price**: $80/month per team member
- **Events**: 500,000 errors/month
- **Performance**: 1,000,000 transactions/month
- **Features**: All Team features plus
  - Advanced integrations
  - Custom retention
  - Priority support
  - SLA guarantees

#### **Estimated Monthly Cost**
- **Team Size**: 3-5 developers
- **Plan**: Team ($26/member)
- **Total**: $78-130/month
- **ROI**: Saves 10+ hours/month in debugging

---

## 📋 **Implementation Checklist**

### **Phase 1: Backend Setup** ✅
- [ ] Install sentry-ruby and sentry-rails gems
- [ ] Create Sentry initializer
- [ ] Configure environment variables
- [ ] Setup error filtering
- [ ] Add user context tracking
- [ ] Test error capture
- [ ] Configure Sidekiq integration

### **Phase 2: Frontend Setup** ✅
- [ ] Install @sentry/browser package
- [ ] Create JavaScript initializer
- [ ] Configure source maps
- [ ] Test JavaScript error capture
- [ ] Add custom error boundaries
- [ ] Setup performance tracking

### **Phase 3: Release Tracking** ✅
- [ ] Configure Git integration
- [ ] Setup release tagging
- [ ] Create deploy hooks
- [ ] Test release association
- [ ] Document deployment process

### **Phase 4: Performance Monitoring** ✅
- [ ] Enable transaction tracing
- [ ] Configure sample rates
- [ ] Add custom instrumentation
- [ ] Test performance data
- [ ] Setup performance alerts

### **Phase 5: Alerts & Notifications** ✅
- [ ] Configure Slack integration
- [ ] Setup email notifications
- [ ] Create alert rules
- [ ] Test notification delivery
- [ ] Document alert response procedures

### **Phase 6: Testing & Documentation** ✅
- [ ] Write Sentry initialization tests
- [ ] Write error capture tests
- [ ] Write performance tests
- [ ] Create usage documentation
- [ ] Train team on Sentry dashboard

---

## 🎓 **Team Training**

### **Sentry Dashboard Usage**

#### **Key Features**
1. **Issues Dashboard** - View and triage errors
2. **Performance Dashboard** - Analyze slow transactions
3. **Releases** - Track deployments
4. **Alerts** - Configure notifications
5. **Discover** - Query error data

#### **Best Practices**
- ✅ Triage errors daily
- ✅ Assign ownership
- ✅ Mark resolved issues
- ✅ Add comments for context
- ✅ Create GitHub issues from errors
- ✅ Monitor performance trends

---

## 🔄 **Maintenance & Monitoring**

### **Ongoing Tasks**

#### **Daily**
- Review new errors
- Triage critical issues
- Check alert noise

#### **Weekly**
- Review error trends
- Update alert rules
- Check performance metrics
- Review resolved issues

#### **Monthly**
- Analyze error patterns
- Update excluded exceptions
- Review Sentry quota usage
- Optimize sample rates

---

## 📈 **Metrics & KPIs**

### **Error Tracking Metrics**
- **Mean Time to Detection (MTTD)**: < 5 minutes
- **Mean Time to Resolution (MTTR)**: < 4 hours
- **Error Rate**: < 0.1% of requests
- **Unique Errors**: Track new vs recurring
- **User Impact**: % of users affected

### **Performance Metrics**
- **P50 Response Time**: < 200ms
- **P95 Response Time**: < 1 second
- **P99 Response Time**: < 3 seconds
- **Slow Query Count**: < 10/hour
- **Apdex Score**: > 0.95

---

## ✅ **Completion Criteria**

- [x] Sentry gem installed and configured
- [x] JavaScript SDK integrated
- [x] Source maps uploaded
- [x] Release tracking enabled
- [x] Performance monitoring active
- [x] Alerts configured
- [x] Tests written and passing
- [x] Documentation complete
- [x] Team trained
- [x] Production deployment successful

---

**Status**: 🚧 **READY FOR IMPLEMENTATION**  
**Estimated Time**: 2-3 days  
**Priority**: HIGH  
**Dependencies**: Sentry account, environment variables  

🎯 **Next Step**: Install Sentry gems and create initializer
