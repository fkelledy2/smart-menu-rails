# Environment Variables Configuration

This document lists all environment variables used by the Smart Menu Rails application.

## 🔐 **Error Tracking & Monitoring**

### **Sentry Configuration**
```bash
# Sentry DSN for error tracking (required for production/staging)
SENTRY_DSN=https://your-dsn@sentry.io/project-id

# Git commit hash for release tracking (automatically set by Heroku)
HEROKU_SLUG_COMMIT=abc123def456
# Alternative for other deployment platforms
GIT_COMMIT=abc123def456
```

## 📊 **Analytics & Tracking**

### **Segment Analytics**
```bash
# Segment write key for analytics tracking
SEGMENT_WRITE_KEY=your_segment_write_key
```

## 🗄️ **Database Configuration**

### **PostgreSQL**
```bash
# Database URL (automatically set by Heroku Postgres)
DATABASE_URL=postgresql://user:password@host:port/database

# Redis URL for caching and background jobs
REDIS_URL=redis://localhost:6379/0
```

## ☁️ **Cloud Services**

### **Google Cloud Vision API**
```bash
# Google Cloud Vision API credentials
GOOGLE_CLOUD_VISION_CREDENTIALS=path/to/credentials.json
# Or use service account key directly
GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json
```

### **AWS S3 (for file storage)**
```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-bucket-name
```

## 💳 **Payment Processing**

### **Stripe**
```bash
# Stripe API keys
STRIPE_PUBLISHABLE_KEY=pk_live_or_test_key
STRIPE_SECRET_KEY=sk_live_or_test_key
```

## 🎵 **Music Integration**

### **Spotify**
```bash
# Spotify API credentials
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
```

## 🤖 **AI Services**

### **OpenAI**
```bash
# OpenAI API key for AI features
OPENAI_API_KEY=sk-your-openai-api-key
```

### **DeepL Translation**
```bash
# DeepL API key for translation services
DEEPL_API_KEY=your-deepl-api-key
```

## 📧 **Email Configuration**

### **SMTP Settings**
```bash
# Email configuration (adjust based on your provider)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_DOMAIN=yourdomain.com
```

## 🔒 **Security & Authentication**

### **Rails Security**
```bash
# Rails secret key base (automatically generated)
SECRET_KEY_BASE=your-very-long-secret-key

# Devise secret key
DEVISE_SECRET_KEY=your-devise-secret-key
```

## 🚀 **Deployment Configuration**

### **Heroku Specific**
```bash
# Automatically set by Heroku
DYNO=web.1
PORT=3000
RAILS_ENV=production
RACK_ENV=production

# Custom configuration
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

## 🧪 **Development & Testing**

### **Development Tools**
```bash
# Enable specific features in development
FORCE_ANALYTICS=true
SPOTIFY_AUTH_AT_BOOT=true

# Bullet gem configuration (N+1 query detection)
BULLET_ENABLED=true
```

## 📝 **Setup Instructions**

### **Local Development**
1. Copy environment variables to your local `.env` file
2. Update values with your development credentials
3. Never commit `.env` files to version control

### **Production Deployment**
1. Set all required environment variables in your hosting platform
2. Ensure sensitive keys are properly secured
3. Use different credentials for staging and production

### **Required for Basic Functionality**
- `DATABASE_URL` - PostgreSQL database connection
- `REDIS_URL` - Redis for caching and background jobs
- `SECRET_KEY_BASE` - Rails application security

### **Required for Full Functionality**
- `SENTRY_DSN` - Error tracking and monitoring
- `GOOGLE_CLOUD_VISION_CREDENTIALS` - OCR menu processing
- `STRIPE_SECRET_KEY` - Payment processing
- `AWS_S3_BUCKET` - File storage

### **Optional but Recommended**
- `SEGMENT_WRITE_KEY` - User analytics
- `OPENAI_API_KEY` - AI-powered features
- `DEEPL_API_KEY` - Multi-language support
- `SPOTIFY_CLIENT_ID` - Music integration

## 🔧 **Validation**

You can validate your environment configuration by running:

```bash
# Check if all required variables are set
bundle exec rails runner "puts 'Sentry configured' if ENV['SENTRY_DSN'].present?"
bundle exec rails runner "puts 'Database connected' if ActiveRecord::Base.connection.active?"
bundle exec rails runner "puts 'Redis connected' if Redis.new.ping == 'PONG'"
```
