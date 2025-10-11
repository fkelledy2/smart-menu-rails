# Smart Menu Development Guide & Governing Rules

## 📋 **Consolidated Memory Summary**

This document consolidates all critical fixes, optimizations, and lessons learned from recent development work to establish governing rules for future development.

---

## 🚀 **Major Achievements Completed**

### 1. **Performance Optimization - Cache Invalidation Fix**
**Problem Solved**: 6+ second response times due to synchronous cache invalidation cascades
**Root Cause**: Model callbacks triggering synchronous cache operations during order updates
**Solution**: Disabled synchronous cache invalidation in favor of background jobs

**Files Modified**:
- `app/models/ordr.rb` - Disabled `after_update :invalidate_order_caches`
- `app/models/restaurant.rb` - Disabled `after_update :invalidate_restaurant_caches`  
- `app/models/employee.rb` - Disabled `after_update :invalidate_employee_caches`

**Performance Impact**: 6,000ms → <500ms (12x improvement)

### 2. **Routing Error Resolution**
**Problem Solved**: `ActionController::RoutingError (No route matches [PATCH] "/ordrparticipants/623")`
**Root Cause**: Frontend making direct PATCH requests but routes only configured for nested access
**Solution**: Added dual access pattern supporting both authenticated and unauthenticated routes

**Files Modified**:
- `config/routes.rb` - Added `resources :ordrparticipants, only: [:update]`
- `app/controllers/ordrparticipants_controller.rb` - Modified for dual access pattern

### 3. **IdentityCache Error Handling**
**Problem Solved**: `NameError: uninitialized constant IdentityCache::UnsupportedOperation`
**Root Cause**: Constant not available in all environments
**Solution**: Conditional error handling and retry logic

**Files Modified**:
- `app/jobs/cache_invalidation_job.rb` - Enhanced error handling

### 4. **Heroku Deployment Optimization**
**Problem Solved**: Multiple deployment warnings causing build instability
**Root Cause**: Unpinned versions and outdated dependencies
**Solution**: Version pinning and dependency upgrades

**Files Modified**:
- `package.json` - Added engines specification
- `.nvmrc` - Node.js version pinning
- `Gemfile` - Updated Puma and Ruby versions
- `.ruby-version` - Updated Ruby version
- `config/initializers/rswag_*.rb` - Environment-conditional configuration

### 5. **Rswag Deployment Fix**
**Problem Solved**: Asset precompilation failure due to missing Rswag constants
**Root Cause**: Rswag gems only available in development/test but initializers ran in production
**Solution**: Environment-conditional initialization

**Files Modified**:
- `config/initializers/rswag_api.rb` - Added environment checks
- `config/initializers/rswag_ui.rb` - Added environment checks
- `config/routes.rb` - Conditional route mounting

---

## 📐 **Governing Rules for Future Development**

### **Rule 1: Performance-First Architecture**
- ✅ **ALWAYS use background jobs for cache invalidation**
- ❌ **NEVER use synchronous cache operations in model callbacks**
- ✅ **Monitor query counts - keep under 50 per request**
- ✅ **Use eager loading to prevent N+1 queries**
- ✅ **Implement composite database indexes for complex queries**

### **Rule 2: Dual Access Pattern for Routes**
- ✅ **Support both authenticated and unauthenticated access where needed**
- ✅ **Use nested routes for authenticated management interfaces**
- ✅ **Use direct routes for unauthenticated customer interfaces**
- ✅ **Always implement proper authorization checks**

### **Rule 3: Environment-Aware Configuration**
- ✅ **Make all development/test-only gems conditional**
- ✅ **Use environment checks for initializers**
- ✅ **Separate production and development configurations**
- ❌ **NEVER assume gems are available in all environments**

### **Rule 4: Version Management & Deployment**
- ✅ **Pin all dependency versions (Node.js, Yarn, Ruby, gems)**
- ✅ **Use minimum version specifications for flexibility**
- ✅ **Keep dependencies updated for security patches**
- ✅ **Test locally before deploying version changes**

### **Rule 5: Error Handling & Resilience**
- ✅ **Always use conditional checks for optional constants**
- ✅ **Implement graceful degradation for external services**
- ✅ **Log errors but don't break application flow**
- ✅ **Use retry logic for transient failures**

### **Rule 6: Cache Strategy**
- ✅ **Use Redis for production caching with CAS support**
- ✅ **Implement background cache invalidation**
- ✅ **Use selective cache clearing, not cascade invalidation**
- ✅ **Monitor cache hit rates and performance**

### **Rule 7: Database Optimization**
- ✅ **Add composite indexes for multi-column queries**
- ✅ **Use includes() for eager loading associations**
- ✅ **Monitor slow query logs regularly**
- ✅ **Optimize before deploying to production**

### **Rule 8: Security & Access Control**
- ✅ **Implement authorization for all sensitive operations**
- ✅ **Use session-based validation for user actions**
- ✅ **Separate public and private API endpoints**
- ✅ **Never expose internal documentation in production**

---

## 🛠️ **Development Workflow Rules**

### **Before Making Changes**
1. **Read existing code and understand current patterns**
2. **Check for similar implementations in the codebase**
3. **Consider performance implications of changes**
4. **Plan for both authenticated and unauthenticated access**

### **During Development**
1. **Use background jobs for long-running operations**
2. **Add proper error handling and logging**
3. **Test in both development and production-like environments**
4. **Monitor query counts and performance metrics**

### **Before Deployment**
1. **Run performance tests locally**
2. **Check for environment-specific configurations**
3. **Verify all dependencies are properly pinned**
4. **Test asset precompilation**

### **After Deployment**
1. **Monitor application logs for errors**
2. **Check performance metrics and response times**
3. **Verify cache invalidation is working properly**
4. **Monitor database query performance**

---

## 📊 **Performance Benchmarks to Maintain**

| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| Response Time | <500ms | >2000ms |
| Database Queries | <50 per request | >100 per request |
| Cache Hit Rate | >80% | <50% |
| Background Job Processing | <30s | >2min |

---

## 🚨 **Red Flags to Watch For**

### **Performance Red Flags**
- Response times >2 seconds
- Database queries >100 per request
- Synchronous cache operations in controllers
- N+1 query patterns in logs

### **Architecture Red Flags**
- Hardcoded environment assumptions
- Missing authorization checks
- Unpinned dependency versions
- Synchronous external API calls

### **Deployment Red Flags**
- Asset precompilation failures
- Missing environment variables
- Gem loading errors in production
- Version compatibility warnings

---

## 🔧 **Emergency Procedures**

### **Performance Issues**
1. Check for synchronous cache invalidation
2. Monitor database query counts
3. Verify background jobs are processing
4. Check Redis connectivity and performance

### **Deployment Issues**
1. Verify all gems are available in target environment
2. Check for environment-conditional configurations
3. Ensure all versions are properly pinned
4. Test asset precompilation locally

### **Routing Issues**
1. Verify both nested and direct routes exist where needed
2. Check authorization logic for different access patterns
3. Ensure frontend is using correct endpoints
4. Test both authenticated and unauthenticated flows

---

## 📚 **Key Files to Monitor**

### **Performance Critical**
- `app/jobs/cache_invalidation_job.rb`
- `app/models/ordr.rb`
- `config/initializers/cache_store.rb`

### **Routing & Access**
- `config/routes.rb`
- `app/controllers/ordrparticipants_controller.rb`
- `app/controllers/ordrs_controller.rb`

### **Deployment Critical**
- `Gemfile`
- `package.json`
- `config/initializers/rswag_*.rb`

---

**Last Updated**: October 9, 2025  
**Status**: Active Development Guide  
**Next Review**: After next major feature deployment
