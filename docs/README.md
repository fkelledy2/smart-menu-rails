# SmartMenu Documentation

Comprehensive documentation for the SmartMenu restaurant management application.

---

## 📁 Folder Structure

### **New Organization (November 2025)**

The documentation has been reorganized into logical categories for easier navigation:

#### **📱 ui-ux/** 
User interface and user experience documentation
- Mobile optimization phases (Customer, Staff, Enhanced UX)
- Design system updates and complete redesign summary
- Interactive features (auto-scroll, image previews, time display)
- Layout improvements and space optimization

#### **⚡ features/** 
Feature implementation documentation
- Menu time restrictions
- Menu sorting
- Payment processing
- Order management
- And more...

#### **🌍 localization/** 
Internationalization (i18n) documentation
- Localization audits and gap analysis
- Automatic locale detection
- Translation coverage reports
- Multi-language support

#### **🐛 bug-fixes/** 
Bug fix documentation and solutions
- Auto-save fixes
- Data integrity fixes
- JavaScript and UI fixes
- Includes root cause analysis and solutions

#### **🔧 rake-tasks/** 
Rake task documentation
- Menu image generation
- Data processing tasks
- Catalog management
- Usage examples and implementation details

#### **📋 project-management/** 
High-level project documentation
- Development roadmaps
- TODO summaries
- Project status and planning

### **Technical Documentation Folders**

#### **🏗️ architecture/** 
System architecture and design patterns
- Application structure
- Design decisions
- Integration patterns

#### **💾 database/** 
Database documentation
- Schema design
- Optimization strategies
- Cache implementations
- Query performance

#### **💻 frontend/** 
Frontend technical documentation
- JavaScript implementations
- CSS/SCSS organization
- Component structure

#### **🛠️ development/** 
Development guides and setup
- Environment setup
- Development workflows
- Coding standards

#### **✅ testing/** 
Testing documentation
- Test strategies
- Test coverage reports
- Integration tests
- Performance tests

#### **⚡ performance/** 
Performance optimization documentation
- Query optimization
- Caching strategies
- Load testing results

#### **🔒 security/** 
Security documentation
- Security audits
- Best practices
- Vulnerability fixes

#### **🚀 deployment/** 
Deployment and operations
- Deployment guides
- Environment configuration
- Server setup

#### **📊 monitoring/** 
Application monitoring
- Logging strategies
- Error tracking
- Performance monitoring

#### **💼 business/** 
Business logic and requirements
- Business rules
- Domain models
- Use cases

#### **📜 javascript/** 
JavaScript-specific documentation
- JS modules
- Frontend libraries

#### **⭐ bestpractice/** 
Best practices and guidelines
- Code style
- Patterns

#### **📦 legacy/** 
Legacy documentation and archived items
- Old implementations
- Deprecated features

---

## 🚀 Getting Started

### For New Developers
1. Read `project-management/development_roadmap.md` for project overview
2. Review `architecture/` for system design understanding
3. Check `development/` for environment setup
4. Explore `features/` for implemented functionality

### For UI/UX Work
1. Start with `ui-ux/REDESIGN_COMPLETE_SUMMARY.md`
2. Review mobile optimization docs in `ui-ux/`
3. Check `frontend/` for technical implementation details

### For Feature Development
1. Review `features/` for existing implementations
2. Check `database/` for schema information
3. Refer to `testing/` for test strategies
4. Follow `bestpractice/` guidelines

### For Bug Fixes
1. Check `bug-fixes/` for similar issues
2. Review `testing/` for test coverage
3. Document your fix in `bug-fixes/`

---

## 📝 Documentation Standards

### When Adding New Documentation

1. **Choose the Right Folder**
   - UI/design changes → `ui-ux/`
   - New features → `features/`
   - Bug fixes → `bug-fixes/`
   - Rake tasks → `rake-tasks/`
   - i18n work → `localization/`
   - Database changes → `database/`

2. **Use Clear Filenames**
   - Use UPPERCASE for standalone docs: `MENU_ITEM_IMAGE_HOVER_PREVIEW.md`
   - Use lowercase-with-hyphens for technical docs: `database-optimization.md`
   - Be descriptive and specific

3. **Document Structure**
   ```markdown
   # Title
   **Date:** YYYY-MM-DD
   **Feature/Fix:** Description
   
   ## Overview
   ## Implementation Details
   ## Testing
   ## Related Documentation
   ```

4. **Include Code Examples**
   - Show before/after code
   - Include usage examples
   - Add configuration snippets

5. **Keep Documentation Current**
   - Update docs when code changes
   - Archive old documentation to `legacy/`
   - Reference related docs

---

## 🔗 Quick Links

### Most Important Documents
- **Project Roadmap**: `project-management/development_roadmap.md`
- **Design System**: `ui-ux/REDESIGN_COMPLETE_SUMMARY.md`
- **Database Optimization**: `database/README.md`
- **Development Guide**: `development/development-guide-and-rules.md`

### Recent Updates (November 2025)
- Customer Preview Implementation (`ui-ux/`)
- Menu Item Image Hover Preview (`ui-ux/`)
- Menu Images Generate All Task Update (`rake-tasks/`)
- Mobile Optimization Phases 1-2 (`ui-ux/`)

### Key Technical Docs
- **Architecture**: `architecture/README.md`
- **Database**: `database/README.md`
- **Performance**: `performance/performance-optimization-summary.md`
- **JavaScript**: `javascript/javascript-optimization-analysis.md`

---

## 📊 Folder Overview

| Folder | Purpose | Key Documents |
|--------|---------|---------------|
| **ui-ux** | UI/UX improvements | REDESIGN_COMPLETE_SUMMARY.md |
| **features** | Feature specs | MENU_TIME_RESTRICTIONS.md |
| **localization** | i18n documentation | COMPLETE_LOCALIZATION_AUDIT.md |
| **bug-fixes** | Bug documentation | AUTO_SAVE_FINAL_SOLUTION.md |
| **rake-tasks** | Rake task docs | MENU_IMAGES_GENERATE_ALL_UPDATE.md |
| **project-management** | Planning docs | development_roadmap.md |
| **database** | DB optimization | database-optimization.md |
| **frontend** | Frontend tech | Component docs |
| **testing** | Test strategies | Test coverage reports |
| **deployment** | Deploy guides | heroku-deployment-remediation.md |

---

## 🤝 Contributing

When contributing documentation:

1. **Place in Correct Folder** - Use folder structure above
2. **Follow Naming Convention** - Consistent file naming
3. **Include Examples** - Code, screenshots, commands
4. **Link Related Docs** - Cross-reference related documentation
5. **Update READMEs** - Update folder READMEs when adding new docs
6. **Keep It Current** - Update docs with code changes

---

## 🏷️ Document Naming Conventions

### UI/UX & Feature Docs
- **UPPERCASE_WITH_UNDERSCORES.md** for standalone feature/fix docs
- Example: `MENU_ITEM_IMAGE_HOVER_PREVIEW.md`

### Technical Docs
- **lowercase-with-hyphens.md** for technical documentation
- Example: `database-optimization-phase-2.md`

### Phase/Version Docs
- Include version/phase when relevant: `PHASE_1_MOBILE_OPTIMIZATION.md`

### General Guidelines
- Use descriptive names
- Avoid abbreviations
- Be specific: `AUTO_SAVE_FINAL_SOLUTION.md` not `AUTO_SAVE_FIX.md`

---

## 📧 Questions?

If you're unsure where documentation belongs:
1. Check existing similar documentation
2. Review folder README files
3. Default to the most specific applicable folder
4. Each folder has a README.md with detailed guidance

---

**Last Reorganization**: November 12, 2025  
**Total Categories**: 20+ organized folders  
**Maintained By**: Development Team
