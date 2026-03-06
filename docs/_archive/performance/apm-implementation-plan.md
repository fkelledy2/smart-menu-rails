# Application Performance Monitoring (APM) Implementation Plan

## 🎯 **Executive Summary**

This document outlines the comprehensive implementation plan for Application Performance Monitoring (APM) in the Smart Menu Rails application. The APM system will provide real-time performance tracking, memory usage monitoring, response time analysis, and performance regression detection to maintain and improve the application's performance.

**Current Status**: Response times <500ms, 85-95% cache hit rates, 12x performance improvement achieved
**Target**: Real-time monitoring, <100ms analytics, proactive issue detection, comprehensive performance insights

---

## 📊 **Current Performance Baseline**

### **Existing Performance Achievements**
- **Response Times**: Reduced from 6,000ms to <500ms (12x improvement)
- **Database Performance**: 40-60% improvement through caching optimization
- **Cache Hit Rates**: 85-95% across models using IdentityCache
- **JavaScript Bundle**: 60% reduction in size
- **Test Coverage**: 45.62% line coverage, 42.03% branch coverage
- **Zero Test Failures**: 3,347 tests passing, 0 failures, 0 errors

### **Performance Monitoring Gaps**
- **No real-time performance tracking** across controllers
- **No memory usage monitoring** or leak detection
- **No response time analysis** by endpoint/user type
- **No performance regression detection** in CI/CD
- **Limited visibility** into production performance patterns

---

## 🏗️ **APM Architecture Design**

### **1. Multi-Layered Monitoring Strategy**

#### **Application Layer Monitoring**
```ruby
# Real-time performance tracking for all controllers
class ApplicationController < ActionController::Base
  include PerformanceMonitoring
  
  around_action :track_performance
  before_action :start_memory_tracking
  after_action :log_performance_metrics
end
```

#### **Database Layer Monitoring**
```ruby
# Query performance tracking and analysis
class DatabasePerformanceMonitor
  def self.track_query(sql, duration, backtrace)
    # Log slow queries, analyze patterns, detect N+1
  end
end
```

#### **Memory Layer Monitoring**
```ruby
# Memory usage and leak detection
class MemoryMonitor
  def self.track_memory_usage
    # Monitor heap size, object allocation, GC metrics
  end
end
```

### **2. Performance Metrics Collection**

#### **Core Metrics**
- **Response Time**: Per endpoint, per user type, percentiles (50th, 95th, 99th)
- **Memory Usage**: Heap size, object allocation rate, GC frequency
- **Database Performance**: Query count, duration, cache hit rates
- **Cache Performance**: Hit/miss rates, invalidation patterns
- **Error Rates**: 4xx/5xx responses, exception frequency

#### **Business Metrics**
- **User Journey Performance**: Registration, menu creation, order processing
- **Feature Usage**: Performance correlation with feature adoption
- **Peak Load Handling**: Restaurant rush hours performance
- **Geographic Performance**: Response times by user location

### **3. Real-Time Dashboard System**

#### **Performance Dashboard Components**
```erb
<!-- Real-time performance dashboard -->
<div id="apm-dashboard">
  <div class="metric-card" data-metric="response-time">
    <h3>Response Time</h3>
    <div class="current-value"><%= @current_response_time %>ms</div>
    <div class="trend-chart" data-chart="response-time-trend"></div>
  </div>
  
  <div class="metric-card" data-metric="memory-usage">
    <h3>Memory Usage</h3>
    <div class="current-value"><%= @current_memory_usage %>MB</div>
    <div class="trend-chart" data-chart="memory-trend"></div>
  </div>
  
  <div class="metric-card" data-metric="cache-performance">
    <h3>Cache Hit Rate</h3>
    <div class="current-value"><%= @cache_hit_rate %>%</div>
    <div class="trend-chart" data-chart="cache-trend"></div>
  </div>
</div>
```

---

## 🔧 **Implementation Strategy**

### **Phase 1: Core APM Infrastructure (Week 1)**

#### **1.1 Performance Tracking Middleware**
```ruby
# app/middleware/performance_tracker.rb
class PerformanceTracker
  def initialize(app)
    @app = app
  end

  def call(env)
    start_time = Time.current
    memory_before = get_memory_usage
    
    status, headers, response = @app.call(env)
    
    duration = (Time.current - start_time) * 1000 # Convert to ms
    memory_after = get_memory_usage
    memory_delta = memory_after - memory_before
    
    log_performance_metrics(env, status, duration, memory_delta)
    
    [status, headers, response]
  end
  
  private
  
  def log_performance_metrics(env, status, duration, memory_delta)
    PerformanceMetric.create!(
      endpoint: "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}",
      response_time: duration,
      memory_usage: memory_delta,
      status_code: status,
      timestamp: Time.current,
      user_id: extract_user_id(env),
      controller: extract_controller(env),
      action: extract_action(env)
    )
  end
end
```

#### **1.2 Database Query Monitoring**
```ruby
# app/lib/database_performance_monitor.rb
class DatabasePerformanceMonitor
  def self.setup_monitoring
    ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
      duration = (finish - start) * 1000 # Convert to ms
      
      if duration > SLOW_QUERY_THRESHOLD
        log_slow_query(payload[:sql], duration, payload[:name])
      end
      
      track_query_patterns(payload[:sql], duration)
    end
  end
  
  private
  
  def self.log_slow_query(sql, duration, name)
    SlowQuery.create!(
      sql: sql,
      duration: duration,
      query_name: name,
      timestamp: Time.current,
      backtrace: caller[0..10]
    )
  end
end
```

#### **1.3 Memory Monitoring Service**
```ruby
# app/services/memory_monitoring_service.rb
class MemoryMonitoringService
  def self.track_memory_usage
    gc_stats = GC.stat
    memory_stats = get_process_memory
    
    MemoryMetric.create!(
      heap_size: gc_stats[:heap_allocated_pages] * 16384, # 16KB per page
      heap_free: gc_stats[:heap_free_slots],
      objects_allocated: gc_stats[:total_allocated_objects],
      gc_count: gc_stats[:count],
      rss_memory: memory_stats[:rss],
      timestamp: Time.current
    )
  end
  
  def self.detect_memory_leaks
    recent_metrics = MemoryMetric.where('timestamp > ?', 1.hour.ago)
    trend = calculate_memory_trend(recent_metrics)
    
    if trend > MEMORY_LEAK_THRESHOLD
      alert_memory_leak(trend)
    end
  end
end
```

### **Phase 2: Real-Time Analytics (Week 2)**

#### **2.1 Performance Analytics Controller**
```ruby
# app/controllers/performance_analytics_controller.rb
class PerformanceAnalyticsController < ApplicationController
  before_action :authenticate_admin!
  
  def dashboard
    @current_metrics = PerformanceMetricsService.current_snapshot
    @performance_trends = PerformanceMetricsService.trends(24.hours)
    @slow_endpoints = PerformanceMetricsService.slow_endpoints(1.hour)
  end
  
  def api_metrics
    render json: {
      response_times: response_time_data,
      memory_usage: memory_usage_data,
      cache_performance: cache_performance_data,
      error_rates: error_rate_data
    }
  end
  
  def endpoint_analysis
    endpoint = params[:endpoint]
    timeframe = params[:timeframe] || '24h'
    
    @analysis = EndpointAnalysisService.analyze(endpoint, timeframe)
    render json: @analysis
  end
end
```

#### **2.2 Real-Time Performance Service**
```ruby
# app/services/performance_metrics_service.rb
class PerformanceMetricsService
  def self.current_snapshot
    {
      avg_response_time: calculate_avg_response_time(5.minutes),
      current_memory_usage: get_current_memory_usage,
      cache_hit_rate: calculate_cache_hit_rate(5.minutes),
      active_users: count_active_users(5.minutes),
      error_rate: calculate_error_rate(5.minutes)
    }
  end
  
  def self.trends(timeframe)
    metrics = PerformanceMetric.where('timestamp > ?', timeframe.ago)
    
    {
      response_time_trend: group_by_time(metrics, :response_time),
      memory_trend: group_by_time(MemoryMetric.recent(timeframe), :rss_memory),
      cache_trend: group_by_time(metrics, :cache_hit_rate),
      error_trend: group_by_time(metrics.where('status_code >= 400'), :count)
    }
  end
  
  def self.slow_endpoints(timeframe)
    PerformanceMetric
      .where('timestamp > ?', timeframe.ago)
      .group(:endpoint)
      .average(:response_time)
      .sort_by { |_, avg_time| -avg_time }
      .first(10)
  end
end
```

### **Phase 3: Performance Regression Detection (Week 3)**

#### **3.1 CI/CD Performance Testing**
```ruby
# test/performance/performance_regression_test.rb
class PerformanceRegressionTest < ActionDispatch::IntegrationTest
  PERFORMANCE_THRESHOLDS = {
    'GET /restaurants' => 200, # ms
    'POST /ordrs' => 300,
    'GET /menus/:id' => 150,
    'GET /analytics/dashboard' => 500
  }.freeze
  
  test "performance regression detection" do
    PERFORMANCE_THRESHOLDS.each do |endpoint, threshold|
      method, path = endpoint.split(' ')
      
      benchmark_result = Benchmark.measure do
        case method
        when 'GET'
          get path.gsub(':id', '1')
        when 'POST'
          post path, params: test_params_for(path)
        end
      end
      
      response_time = benchmark_result.real * 1000 # Convert to ms
      
      assert response_time < threshold,
        "Performance regression detected: #{endpoint} took #{response_time}ms (threshold: #{threshold}ms)"
    end
  end
end
```

#### **3.2 Automated Performance Alerts**
```ruby
# app/jobs/performance_monitoring_job.rb
class PerformanceMonitoringJob < ApplicationJob
  queue_as :monitoring
  
  def perform
    check_response_time_regression
    check_memory_usage_spikes
    check_error_rate_increases
    check_cache_performance_degradation
  end
  
  private
  
  def check_response_time_regression
    current_avg = PerformanceMetricsService.avg_response_time(15.minutes)
    baseline_avg = PerformanceMetricsService.avg_response_time(24.hours, 1.week.ago)
    
    if current_avg > baseline_avg * 1.5 # 50% increase
      AlertService.send_performance_alert(
        type: 'response_time_regression',
        current: current_avg,
        baseline: baseline_avg,
        severity: 'high'
      )
    end
  end
end
```

### **Phase 4: Advanced Analytics & Visualization (Week 4)**

#### **4.1 Performance Visualization Dashboard**
```javascript
// app/javascript/performance_dashboard.js
class PerformanceDashboard {
  constructor() {
    this.initializeCharts();
    this.startRealTimeUpdates();
  }
  
  initializeCharts() {
    this.responseTimeChart = new Chart(
      document.getElementById('response-time-chart'),
      this.getResponseTimeConfig()
    );
    
    this.memoryChart = new Chart(
      document.getElementById('memory-chart'),
      this.getMemoryConfig()
    );
    
    this.cacheChart = new Chart(
      document.getElementById('cache-chart'),
      this.getCacheConfig()
    );
  }
  
  startRealTimeUpdates() {
    setInterval(() => {
      this.updateMetrics();
    }, 5000); // Update every 5 seconds
  }
  
  async updateMetrics() {
    try {
      const response = await fetch('/performance_analytics/api_metrics');
      const data = await response.json();
      
      this.updateResponseTimeChart(data.response_times);
      this.updateMemoryChart(data.memory_usage);
      this.updateCacheChart(data.cache_performance);
      this.updateErrorRates(data.error_rates);
    } catch (error) {
      console.error('Failed to update performance metrics:', error);
    }
  }
}
```

---

## 📊 **Database Schema for APM**

### **Performance Metrics Table**
```ruby
# db/migrate/create_performance_metrics.rb
class CreatePerformanceMetrics < ActiveRecord::Migration[7.0]
  def change
    create_table :performance_metrics do |t|
      t.string :endpoint, null: false
      t.float :response_time, null: false # milliseconds
      t.integer :memory_usage # bytes
      t.integer :status_code, null: false
      t.references :user, foreign_key: true, null: true
      t.string :controller
      t.string :action
      t.datetime :timestamp, null: false
      t.json :additional_data
      
      t.timestamps
    end
    
    add_index :performance_metrics, [:endpoint, :timestamp]
    add_index :performance_metrics, [:timestamp]
    add_index :performance_metrics, [:response_time]
    add_index :performance_metrics, [:status_code, :timestamp]
  end
end
```

### **Memory Metrics Table**
```ruby
# db/migrate/create_memory_metrics.rb
class CreateMemoryMetrics < ActiveRecord::Migration[7.0]
  def change
    create_table :memory_metrics do |t|
      t.bigint :heap_size, null: false
      t.bigint :heap_free
      t.bigint :objects_allocated
      t.integer :gc_count
      t.bigint :rss_memory
      t.datetime :timestamp, null: false
      
      t.timestamps
    end
    
    add_index :memory_metrics, [:timestamp]
    add_index :memory_metrics, [:rss_memory, :timestamp]
  end
end
```

### **Slow Queries Table**
```ruby
# db/migrate/create_slow_queries.rb
class CreateSlowQueries < ActiveRecord::Migration[7.0]
  def change
    create_table :slow_queries do |t|
      t.text :sql, null: false
      t.float :duration, null: false # milliseconds
      t.string :query_name
      t.text :backtrace
      t.datetime :timestamp, null: false
      
      t.timestamps
    end
    
    add_index :slow_queries, [:duration, :timestamp]
    add_index :slow_queries, [:timestamp]
  end
end
```

---

## 🧪 **Testing Strategy**

### **Unit Tests for APM Components**
```ruby
# test/services/performance_metrics_service_test.rb
class PerformanceMetricsServiceTest < ActiveSupport::TestCase
  test "calculates current performance snapshot" do
    create_performance_metrics
    
    snapshot = PerformanceMetricsService.current_snapshot
    
    assert_not_nil snapshot[:avg_response_time]
    assert_not_nil snapshot[:current_memory_usage]
    assert_not_nil snapshot[:cache_hit_rate]
    assert snapshot[:avg_response_time] > 0
  end
  
  test "detects performance trends" do
    create_trending_metrics
    
    trends = PerformanceMetricsService.trends(1.hour)
    
    assert_not_empty trends[:response_time_trend]
    assert_not_empty trends[:memory_trend]
  end
end
```

### **Integration Tests for Performance Monitoring**
```ruby
# test/integration/performance_monitoring_test.rb
class PerformanceMonitoringTest < ActionDispatch::IntegrationTest
  test "tracks performance metrics for all requests" do
    assert_difference 'PerformanceMetric.count', 1 do
      get restaurants_path
    end
    
    metric = PerformanceMetric.last
    assert_equal 'GET /restaurants', metric.endpoint
    assert metric.response_time > 0
    assert_equal 200, metric.status_code
  end
  
  test "detects slow queries" do
    assert_difference 'SlowQuery.count', 1 do
      # Trigger a slow query
      Restaurant.joins(:menus).includes(:ordrs).limit(1000).to_a
    end
    
    slow_query = SlowQuery.last
    assert slow_query.duration > DatabasePerformanceMonitor::SLOW_QUERY_THRESHOLD
  end
end
```

### **Performance Regression Tests**
```ruby
# test/performance/apm_performance_test.rb
class ApmPerformanceTest < ActionDispatch::IntegrationTest
  test "APM overhead is minimal" do
    # Test without APM
    time_without_apm = Benchmark.measure do
      100.times { get restaurants_path }
    end
    
    # Enable APM
    Rails.application.config.enable_apm = true
    
    # Test with APM
    time_with_apm = Benchmark.measure do
      100.times { get restaurants_path }
    end
    
    # APM should add less than 10% overhead
    overhead = (time_with_apm.real - time_without_apm.real) / time_without_apm.real
    assert overhead < 0.1, "APM overhead too high: #{overhead * 100}%"
  end
end
```

---

## 🚀 **Deployment & Configuration**

### **Environment Configuration**
```ruby
# config/environments/production.rb
Rails.application.configure do
  # APM Configuration
  config.enable_apm = true
  config.apm_sample_rate = 1.0 # Sample 100% in production
  config.slow_query_threshold = 100 # ms
  config.memory_monitoring_interval = 60 # seconds
  config.performance_alert_threshold = 1.5 # 50% increase triggers alert
end

# config/environments/development.rb
Rails.application.configure do
  config.enable_apm = true
  config.apm_sample_rate = 0.1 # Sample 10% in development
  config.slow_query_threshold = 50 # ms
end
```

### **Monitoring Job Scheduling**
```ruby
# config/schedule.rb (whenever gem)
every 5.minutes do
  runner "PerformanceMonitoringJob.perform_later"
end

every 1.hour do
  runner "MemoryMonitoringService.detect_memory_leaks"
end

every 1.day do
  runner "PerformanceCleanupJob.perform_later"
end
```

---

## 📈 **Success Metrics & KPIs**

### **Performance Monitoring KPIs**
- **Response Time Tracking**: 100% endpoint coverage
- **Memory Leak Detection**: <1% false positive rate
- **Performance Regression Detection**: <5 minute detection time
- **Dashboard Load Time**: <2 seconds for real-time updates

### **Business Impact Metrics**
- **Issue Detection Speed**: 90% faster than manual detection
- **Performance Optimization**: 20% additional improvement through insights
- **Downtime Prevention**: 95% reduction in performance-related incidents
- **Developer Productivity**: 30% faster debugging and optimization

### **Technical Metrics**
- **APM Overhead**: <5% performance impact
- **Data Retention**: 30 days detailed, 1 year aggregated
- **Alert Accuracy**: >95% true positive rate
- **Coverage**: 100% of critical user journeys monitored

---

## 🔧 **Maintenance & Operations**

### **Data Retention Strategy**
```ruby
# app/jobs/performance_cleanup_job.rb
class PerformanceCleanupJob < ApplicationJob
  def perform
    # Keep detailed metrics for 30 days
    PerformanceMetric.where('timestamp < ?', 30.days.ago).delete_all
    
    # Keep memory metrics for 7 days
    MemoryMetric.where('timestamp < ?', 7.days.ago).delete_all
    
    # Keep slow queries for 14 days
    SlowQuery.where('timestamp < ?', 14.days.ago).delete_all
    
    # Archive aggregated data for long-term analysis
    PerformanceArchiveService.create_monthly_aggregates
  end
end
```

### **Performance Optimization**
```ruby
# Optimize APM data collection
class OptimizedPerformanceTracker
  def self.should_track?(request)
    # Sample based on configuration
    return false if rand > Rails.application.config.apm_sample_rate
    
    # Always track slow requests
    return true if request.response_time > 1000
    
    # Always track errors
    return true if request.status_code >= 400
    
    true
  end
end
```

---

## 🎯 **Implementation Timeline**

### **Week 1: Core Infrastructure**
- [ ] Performance tracking middleware
- [ ] Database query monitoring
- [ ] Memory monitoring service
- [ ] Basic metrics collection

### **Week 2: Real-Time Analytics**
- [ ] Performance analytics controller
- [ ] Real-time dashboard
- [ ] API endpoints for metrics
- [ ] Chart.js integration

### **Week 3: Regression Detection**
- [ ] CI/CD performance tests
- [ ] Automated alerting system
- [ ] Performance thresholds
- [ ] Notification system

### **Week 4: Advanced Features**
- [ ] Performance visualization
- [ ] Trend analysis
- [ ] Endpoint-specific analysis
- [ ] Memory leak detection

---

## 📋 **Risk Mitigation**

### **Performance Impact Risks**
- **Mitigation**: Configurable sampling rates, async processing
- **Monitoring**: Track APM overhead continuously
- **Fallback**: Ability to disable APM quickly if needed

### **Data Volume Risks**
- **Mitigation**: Automated cleanup jobs, data aggregation
- **Monitoring**: Database size alerts
- **Fallback**: Emergency data purge procedures

### **Alert Fatigue Risks**
- **Mitigation**: Smart thresholds, alert grouping
- **Monitoring**: Alert frequency tracking
- **Fallback**: Alert suppression during maintenance

This comprehensive APM implementation will provide the Smart Menu application with industry-leading performance monitoring capabilities, enabling proactive optimization and maintaining the high performance standards already achieved.
