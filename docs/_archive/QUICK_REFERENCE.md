# Documentation Quick Reference

**Last Updated:** November 12, 2025

---

## 🗂️ Folder Structure at a Glance

```
docs/
├── 📱 ui-ux/                    # UI/UX & Design (14 files)
├── 🌍 localization/             # i18n & Translations (7 files)
├── 🐛 bug-fixes/                # Bug Solutions (7 files)
├── 🔧 rake-tasks/               # Rake Task Docs (2 files)
├── 📋 project-management/       # Roadmaps & Planning (4 files)
├── ⚡ features/                 # Feature Implementations
├── ✅ testing/                  # Testing Documentation
├── 💾 database/                 # Database & Optimization
├── 💻 frontend/                 # Frontend Technical
├── 🏗️ architecture/             # System Architecture
├── 🛠️ development/              # Dev Guides & Setup
├── 🚀 deployment/               # Deployment & Ops
├── 🔒 security/                 # Security Docs
├── ⚡ performance/              # Performance Optimization
└── 📦 legacy/                   # Archived Docs
```

---

## 🎯 Find What You Need

### I need to...

**→ See the design system overview**
```
docs/ui-ux/REDESIGN_COMPLETE_SUMMARY.md
```

**→ Check mobile optimization work**
```
docs/ui-ux/PHASE_1_MOBILE_OPTIMIZATION.md
docs/ui-ux/PHASE_1_CUSTOMER_VIEW_UPDATE.md
docs/ui-ux/PHASE_1_STAFF_VIEW_UPDATE.md
```

**→ Find translation gaps**
```
docs/localization/COMPLETE_LOCALIZATION_AUDIT.md
```

**→ Look up a bug fix**
```
docs/bug-fixes/
```

**→ See rake task usage**
```
docs/rake-tasks/MENU_IMAGES_GENERATE_ALL_UPDATE.md
```

**→ Check project roadmap**
```
docs/project-management/development_roadmap.md
```

**→ Review database optimization**
```
docs/database/README.md
```

**→ Understand system architecture**
```
docs/architecture/README.md
```

---

## 📁 Folder Purposes

| Folder | What's Inside | When to Use |
|--------|---------------|-------------|
| **ui-ux** | Design updates, mobile optimization, visual improvements | Working on UI/design |
| **localization** | i18n audits, translation gaps, locale detection | Adding translations |
| **bug-fixes** | Bug solutions with root cause analysis | Fixing bugs |
| **rake-tasks** | Task documentation and usage examples | Running rake tasks |
| **project-management** | Roadmaps, TODOs, planning docs | Planning work |
| **features** | Feature specifications and implementations | Building features |
| **testing** | Test strategies and coverage | Writing tests |
| **database** | Schema, optimization, caching | Database work |
| **frontend** | JavaScript, CSS, components | Frontend dev |
| **architecture** | System design and patterns | Understanding structure |
| **development** | Setup guides and workflows | Getting started |
| **deployment** | Deploy guides and configs | Deploying app |
| **security** | Security audits and practices | Security work |
| **performance** | Performance optimization | Speed improvements |
| **legacy** | Archived old documentation | Historical reference |

---

## 🚀 Quick Commands

### Find a specific document
```bash
cd docs
find . -name "*IMAGE*" -type f
```

### List all docs in a category
```bash
ls docs/ui-ux/
ls docs/bug-fixes/
ls docs/rake-tasks/
```

### Search across all documentation
```bash
grep -r "menu image" docs/
```

### See folder structure
```bash
tree docs/ -L 2
```

---

## 📝 Adding New Documentation

### 1. Choose the right folder

**Is it about...**
- Visual design? → `ui-ux/`
- Translations? → `localization/`
- A bug you fixed? → `bug-fixes/`
- A rake task? → `rake-tasks/`
- Planning? → `project-management/`
- A new feature? → `features/`
- Testing? → `testing/`
- Database? → `database/`
- Deployment? → `deployment/`

### 2. Name your file

**Standalone docs:** `UPPERCASE_WITH_UNDERSCORES.md`  
**Technical docs:** `lowercase-with-hyphens.md`

### 3. Update the folder README

Add an entry to the folder's `README.md` file.

### 4. Cross-reference

Link to related documentation in other folders.

---

## 🔗 Most Important Documents

1. **Main Index**: `docs/README.md`
2. **Design System**: `docs/ui-ux/REDESIGN_COMPLETE_SUMMARY.md`
3. **Roadmap**: `docs/project-management/development_roadmap.md`
4. **Database**: `docs/database/README.md`
5. **Dev Guide**: `docs/development/development-guide-and-rules.md`

---

## 💡 Tips

### For New Team Members
1. Start with `docs/README.md`
2. Read `docs/project-management/development_roadmap.md`
3. Review `docs/ui-ux/REDESIGN_COMPLETE_SUMMARY.md`
4. Check your specific area folder (frontend, backend, etc.)

### For Bug Fixing
1. Check `docs/bug-fixes/` for similar issues
2. Document your solution in `docs/bug-fixes/`
3. Update related test docs in `docs/testing/`

### For Feature Development
1. Review similar features in `docs/features/`
2. Check database impact in `docs/database/`
3. Plan UI changes in `docs/ui-ux/`
4. Document when complete

---

**Need help?** Check the folder's README.md for detailed guidance!
