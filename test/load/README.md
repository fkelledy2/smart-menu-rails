# Load Testing with k6

This directory contains load testing scripts for the SmartMenu application using [k6](https://k6.io/).

## 📋 Prerequisites

### Install k6

**macOS:**
```bash
brew install k6
```

**Linux:**
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

**Docker:**
```bash
docker pull grafana/k6
```

## 🚀 Quick Start

### 1. Start the Application
```bash
# Terminal 1: Start Rails server
bin/rails server

# Terminal 2: Start Redis (if not running)
redis-server
```

### 2. Run Baseline Test
```bash
k6 run test/load/baseline_test.js
```

### 3. Run Peak Hour Test
```bash
k6 run test/load/peak_hour_test.js
```

## 📊 Available Tests

### Baseline Test (`baseline_test.js`)
- **Purpose**: Establish baseline performance metrics
- **Duration**: ~7 minutes
- **Users**: 10 concurrent
- **Use Case**: Regular performance monitoring

**Run:**
```bash
k6 run test/load/baseline_test.js
```

### Peak Hour Test (`peak_hour_test.js`)
- **Purpose**: Simulate restaurant rush hour
- **Duration**: ~32 minutes
- **Users**: Ramps 0 → 100 → 500 → 0
- **Use Case**: Validate peak load handling

**Run:**
```bash
k6 run test/load/peak_hour_test.js
```

## ⚙️ Configuration

### Environment Variables

Set these before running tests:

```bash
# Base URL (default: http://localhost:3000)
export BASE_URL=https://staging.smartmenu.com

# Test data IDs
export RESTAURANT_ID=your-restaurant-id
export MENU_ID=your-menu-id
export TABLE_ID=your-table-id
export SMARTMENU_ID=your-smartmenu-id

# Test user credentials
export TEST_USER_EMAIL=test@example.com
export TEST_USER_PASSWORD=password123

# Environment tag
export ENVIRONMENT=staging
```

### Custom Configuration

Edit `config.js` to modify:
- Performance thresholds
- Load patterns
- User behavior distribution
- Think time ranges

## 📈 Understanding Results

### Key Metrics

**Response Time:**
- `http_req_duration`: Total request duration
- `p(95)`: 95th percentile (95% of requests faster than this)
- `p(99)`: 99th percentile
- `avg`: Average response time

**Throughput:**
- `http_reqs`: Total number of requests
- `iterations`: Number of complete test iterations
- `vus`: Virtual users (concurrent users)

**Reliability:**
- `http_req_failed`: Percentage of failed requests
- `checks`: Percentage of assertion checks that passed

### Success Criteria

✅ **Passing Test:**
- Response time p(95) < 2000ms
- Response time p(99) < 3000ms
- Error rate < 1%
- Checks pass rate > 95%

❌ **Failing Test:**
- Any threshold exceeded
- Error rate > 1%
- Checks pass rate < 95%

## 🎯 Test Scenarios

### 1. Menu Browsing (40%)
Simulates users browsing the menu:
- Load smartmenu page
- View menu items
- Search functionality

### 2. Order Placement (30%)
Simulates order creation:
- Start new order
- Add items to order
- Confirm order

### 3. Order Status (20%)
Simulates checking order status:
- View current order
- Check order updates
- Real-time status changes

### 4. Payment Processing (10%)
Simulates payment flow:
- Request bill
- Process payment
- Complete order

## 🔧 Advanced Usage

### Run with Custom Options

```bash
# Run with more virtual users
k6 run --vus 100 --duration 5m test/load/baseline_test.js

# Run with custom stages
k6 run --stage 2m:10,5m:50,2m:0 test/load/baseline_test.js

# Output results to file
k6 run --out json=results.json test/load/baseline_test.js
```

### Run in Docker

```bash
docker run --rm -i grafana/k6 run - <test/load/baseline_test.js
```

### Cloud Execution (k6 Cloud)

```bash
# Login to k6 Cloud
k6 login cloud

# Run test in cloud
k6 cloud test/load/peak_hour_test.js
```

## 📊 Capacity Planning

### Generate Capacity Report

```bash
bundle exec rake capacity:report
```

This generates a comprehensive report showing:
- Current baseline metrics
- 10x growth scenario
- 100x growth scenario
- Infrastructure requirements
- Cost estimates
- Recommendations

### Check Load Capacity

```bash
# Check if system can handle 10,000 users
bundle exec rake capacity:check_load[10000]
```

### View Current Utilization

```bash
bundle exec rake capacity:utilization
```

## 🔍 Debugging

### Enable Verbose Logging

```bash
k6 run --http-debug test/load/baseline_test.js
```

### View Detailed Metrics

```bash
k6 run --summary-export=summary.json test/load/baseline_test.js
cat summary.json | jq
```

### Check Individual Requests

Add logging in test scripts:
```javascript
console.log('Response status:', response.status);
console.log('Response time:', response.timings.duration);
console.log('Response body:', response.body);
```

## 🚨 Troubleshooting

### Connection Refused
**Problem:** `dial: connection refused`

**Solution:**
- Ensure Rails server is running
- Check BASE_URL is correct
- Verify firewall settings

### High Error Rate
**Problem:** Many requests failing

**Solution:**
- Check application logs
- Verify database connections
- Ensure Redis is running
- Check for rate limiting

### Slow Response Times
**Problem:** Response times exceed thresholds

**Solution:**
- Check database query performance
- Verify cache hit rates
- Monitor server resources (CPU, memory)
- Review application logs for bottlenecks

## 📚 Best Practices

### 1. Test Regularly
- Run baseline tests daily
- Run peak hour tests weekly
- Run before major releases

### 2. Monitor Trends
- Track metrics over time
- Identify performance regressions
- Set up alerts for degradation

### 3. Realistic Data
- Use production-like data volumes
- Test with realistic user behaviors
- Include edge cases

### 4. Gradual Load
- Always ramp up gradually
- Allow warm-up period
- Ramp down gracefully

### 5. Clean Environment
- Clear caches before testing
- Ensure consistent starting state
- Isolate test environment

## 🎓 Learning Resources

- [k6 Documentation](https://k6.io/docs/)
- [Load Testing Best Practices](https://k6.io/docs/testing-guides/test-types/)
- [Performance Testing Guide](https://k6.io/docs/testing-guides/)
- [k6 Examples](https://k6.io/docs/examples/)

## 📝 Adding New Tests

### 1. Create Test File
```bash
touch test/load/my_new_test.js
```

### 2. Use Template
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, THRESHOLDS } from './config.js';

export const options = {
  stages: [
    { duration: '2m', target: 50 },
    { duration: '5m', target: 50 },
    { duration: '2m', target: 0 }
  ],
  thresholds: THRESHOLDS
};

export default function () {
  const response = http.get(`${BASE_URL}/your-endpoint`);
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time OK': (r) => r.timings.duration < 1000
  });
  
  sleep(1);
}
```

### 3. Run Test
```bash
k6 run test/load/my_new_test.js
```

## 🤝 Contributing

When adding new load tests:
1. Follow existing patterns in `config.js`
2. Use shared utilities from `utils/helpers.js`
3. Add appropriate thresholds
4. Document the test purpose and usage
5. Include in CI/CD pipeline

## 📞 Support

For questions or issues:
- Check k6 documentation
- Review application logs
- Contact DevOps team
- Open GitHub issue

---

**Last Updated:** 2025-10-22  
**Maintained By:** DevOps Team
