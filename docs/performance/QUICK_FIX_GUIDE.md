# 🚨 CRITICAL PERFORMANCE FIX - Quick Start Guide

## ⚠️ URGENT: Your System Cannot Handle Load

**Peak hour test results**: 98.5% failure rate, 60-second timeouts

**This guide will fix it in 30 minutes.**

---

## 🔥 Phase 1: Critical Fixes (Do Right Now)

### Step 1: Stop Your Rails Server

Press `Ctrl+C` in your terminal running Rails

### Step 2: Update Puma Configuration

Edit `config/puma.rb`:

```ruby
# config/puma.rb

# Increase workers and threads for load handling
workers ENV.fetch("WEB_CONCURRENCY") { 4 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 10 }
threads threads_count, threads_count

# Preload app for better memory usage
preload_app!

# Reconnect to database after fork
on_worker_boot do
  ActiveRecord::Base.establish_connection
end

# Increase timeout to prevent premature failures
worker_timeout 120

# Rest of your existing config...
```

### Step 3: Update Database Configuration

Edit `config/database.yml`:

```yaml
# config/database.yml

development:
  primary:
    <<: *default
    database: smart_menu_development
    pool: <%= ENV.fetch("DB_POOL_SIZE", 50).to_i %>  # ← CHANGE THIS from 5 to 50
    checkout_timeout: 5  # ← ADD THIS (fail fast)
```

### Step 4: Enable Development Caching

```bash
bin/rails dev:cache
```

You should see: `Development mode is now being cached.`

### Step 5: Restart Rails Server with New Configuration

```bash
export WEB_CONCURRENCY=4
export RAILS_MAX_THREADS=10
export DB_POOL_SIZE=50

bin/rails server
```

### Step 6: Verify Configuration

In a new terminal, run:

```bash
# Check if caching is enabled
cat tmp/caching-dev.txt
# Should output: yes

# Check environment variables
echo "Workers: $WEB_CONCURRENCY"
echo "Threads: $RAILS_MAX_THREADS"
echo "DB Pool: $DB_POOL_SIZE"
```

### Step 7: Run Baseline Test

```bash
k6 run test/load/baseline_test.js
```

### Expected Results After Phase 1

| Metric | Before | After Phase 1 | Improvement |
|--------|--------|---------------|-------------|
| Average Response | 8.76s | 800ms-1.5s | **83-91%** ↓ |
| p95 Response | 60.0s | 2-3s | **95-97%** ↓ |
| Error Rate | 98.5% | 5-10% | **89-94%** ↓ |
| Checks Passed | 11.7% | 85-90% | **7-8x** ↑ |

---

## ✅ Verification Checklist

After restarting your server, verify:

- [ ] Server starts without errors
- [ ] You see "4 workers" in Puma output
- [ ] `tmp/caching-dev.txt` contains "yes"
- [ ] Baseline test shows < 2s response times
- [ ] Error rate < 10%
- [ ] Checks pass > 85%

---

## 🎯 If Results Are Still Poor

### Check 1: Database Connections

```bash
# In Rails console
bin/rails console

# Check pool size
ActiveRecord::Base.connection_pool.size
# Should output: 50
```

### Check 2: Puma Workers

Look for this in server output:
```
* Workers: 4
* Threads: 10 (10 max)
```

### Check 3: Caching Enabled

```bash
# In Rails console
Rails.cache.write('test', 'value')
Rails.cache.read('test')
# Should output: "value"
```

---

## 📊 Next Steps After Phase 1

Once Phase 1 is working (response times < 2s, error rate < 10%):

1. **Add Fragment Caching** (see full analysis document)
2. **Add Database Indexes** (see full analysis document)
3. **Run Peak Hour Test** to verify full load handling

---

## 🆘 Troubleshooting

### Problem: Server won't start

**Solution**: Check for syntax errors in config files
```bash
ruby -c config/puma.rb
ruby -c config/database.yml
```

### Problem: "Too many connections" error

**Solution**: Reduce DB pool or increase PostgreSQL max_connections
```bash
# Check PostgreSQL max connections
psql -U your_user -d smart_menu_development -c "SHOW max_connections;"

# If < 100, increase it in postgresql.conf
# Then restart PostgreSQL
```

### Problem: Still seeing 60s timeouts

**Solution**: Check if worker_timeout is set in puma.rb
```ruby
worker_timeout 120  # Should be in config/puma.rb
```

### Problem: Caching not working

**Solution**: Restart server after enabling cache
```bash
bin/rails dev:cache
# Then restart server
```

---

## 📞 Support

If issues persist after Phase 1:

1. Check `log/development.log` for errors
2. Review full analysis: `docs/performance/peak-hour-test-analysis.md`
3. Run with verbose logging:
   ```bash
   RAILS_LOG_LEVEL=debug bin/rails server
   ```

---

## 🎉 Success!

Once your baseline test shows:
- ✅ Average response < 1.5s
- ✅ p95 response < 3s
- ✅ Error rate < 10%
- ✅ Checks pass > 85%

**You're ready for Phase 2!** See the full analysis document for next steps.

---

**Time Required**: 30 minutes  
**Difficulty**: Easy (config changes only)  
**Impact**: 80-90% performance improvement  
**Status**: 🔴 **CRITICAL - DO IMMEDIATELY**
