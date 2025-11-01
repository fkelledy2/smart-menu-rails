# Frontend Linting Implementation Plan
## Smart Menu Rails Application

**Created**: November 1, 2025  
**Status**: 🚧 **IN PROGRESS**  
**Priority**: HIGH  

---

## 🎯 **Objective**

Implement comprehensive frontend linting and code formatting to ensure JavaScript/CSS code quality, consistency, and maintainability across the Smart Menu application.

---

## 📊 **Current State Analysis**

### **JavaScript/TypeScript Codebase**
- **Location**: `app/javascript/`
- **Structure**: 
  - 30+ standalone JS files (controllers, pages)
  - `modules/` directory (11 items)
  - `components/` directory (3 items)
  - `utils/` directory (7 items)
  - `channels/` directory (7 items)
  - `controllers/` directory (4 items - Stimulus)
- **Build Tool**: esbuild
- **Test Framework**: Vitest (47 tests passing)
- **Current Linting**: ❌ None

### **CSS/SCSS Codebase**
- **Location**: `app/assets/stylesheets/`
- **Structure**:
  - Main file: `application.bootstrap.scss`
  - `components/` directory (5 items)
  - `pages/` directory (3 items)
  - `themes/` directory (2 items)
  - Utility files: `utility.scss`, `kitchen_dashboard.css`
- **Build Tool**: Sass + PostCSS + Autoprefixer
- **Current Linting**: ❌ None

### **Package Manager**
- **Tool**: Yarn 1.22.22
- **Node Version**: 22.11.0
- **Dependencies**: Bootstrap 5.3.3, Stimulus 3.2.2, Turbo 8.0.3

---

## 🎯 **Implementation Strategy**

### **Phase 1: ESLint Setup** (Priority: CRITICAL)

#### **1.1 Install ESLint Dependencies**
```bash
yarn add --dev eslint @eslint/js eslint-plugin-import
```

#### **1.2 Create ESLint Configuration**
**File**: `.eslintrc.json`

**Configuration Strategy**:
- **Base**: ESLint recommended rules
- **Environment**: Browser, ES2022, Node
- **Parser Options**: ES modules, modern syntax
- **Plugins**: Import resolution
- **Custom Rules**: Tailored to Rails + esbuild setup

**Key Rules**:
- ✅ No unused variables
- ✅ No console.log in production
- ✅ Consistent quotes (single)
- ✅ Semicolons required
- ✅ Proper indentation (2 spaces)
- ✅ No var declarations (use const/let)
- ✅ Arrow function consistency

#### **1.3 Add ESLint Scripts**
**package.json additions**:
```json
{
  "scripts": {
    "lint:js": "eslint app/javascript/**/*.js",
    "lint:js:fix": "eslint app/javascript/**/*.js --fix"
  }
}
```

#### **1.4 Create .eslintignore**
**File**: `.eslintignore`
```
node_modules/
app/assets/builds/
public/
vendor/
coverage/
tmp/
```

---

### **Phase 2: Prettier Setup** (Priority: HIGH)

#### **2.1 Install Prettier Dependencies**
```bash
yarn add --dev prettier eslint-config-prettier eslint-plugin-prettier
```

#### **2.2 Create Prettier Configuration**
**File**: `.prettierrc.json`

**Configuration**:
```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "tabWidth": 2,
  "printWidth": 100,
  "arrowParens": "always",
  "endOfLine": "lf"
}
```

#### **2.3 Create .prettierignore**
**File**: `.prettierignore`
```
node_modules/
app/assets/builds/
public/
vendor/
coverage/
tmp/
*.min.js
```

#### **2.4 Add Prettier Scripts**
**package.json additions**:
```json
{
  "scripts": {
    "format": "prettier --write \"app/javascript/**/*.js\"",
    "format:check": "prettier --check \"app/javascript/**/*.js\""
  }
}
```

#### **2.5 Integrate Prettier with ESLint**
Update `.eslintrc.json` to extend `prettier` config (disables conflicting rules)

---

### **Phase 3: Stylelint Setup** (Priority: MEDIUM)

#### **3.1 Install Stylelint Dependencies**
```bash
yarn add --dev stylelint stylelint-config-standard-scss stylelint-config-prettier-scss
```

#### **3.2 Create Stylelint Configuration**
**File**: `.stylelintrc.json`

**Configuration Strategy**:
- **Base**: Standard SCSS rules
- **Prettier Integration**: No conflicts with formatting
- **Custom Rules**: Bootstrap 5 compatibility

**Key Rules**:
- ✅ No duplicate selectors
- ✅ Color format consistency
- ✅ Property order (logical grouping)
- ✅ No vendor prefixes (handled by autoprefixer)
- ✅ Selector naming conventions
- ✅ Declaration block consistency

#### **3.3 Create .stylelintignore**
**File**: `.stylelintignore`
```
node_modules/
app/assets/builds/
public/
vendor/
coverage/
tmp/
*.min.css
```

#### **3.4 Add Stylelint Scripts**
**package.json additions**:
```json
{
  "scripts": {
    "lint:css": "stylelint \"app/assets/stylesheets/**/*.{css,scss}\"",
    "lint:css:fix": "stylelint \"app/assets/stylesheets/**/*.{css,scss}\" --fix"
  }
}
```

---

### **Phase 4: Pre-commit Integration** (Priority: MEDIUM)

#### **4.1 Install Husky & lint-staged**
```bash
yarn add --dev husky lint-staged
npx husky install
```

#### **4.2 Configure lint-staged**
**File**: `.lintstagedrc.json`

```json
{
  "app/javascript/**/*.js": [
    "eslint --fix",
    "prettier --write"
  ],
  "app/assets/stylesheets/**/*.{css,scss}": [
    "stylelint --fix"
  ]
}
```

#### **4.3 Create Pre-commit Hook**
```bash
npx husky add .husky/pre-commit "npx lint-staged"
```

#### **4.4 Add Husky Setup Script**
**package.json additions**:
```json
{
  "scripts": {
    "prepare": "husky install"
  }
}
```

---

## 📋 **Implementation Steps**

### **Step 1: ESLint Setup** ✅
- [x] Analyze JavaScript codebase
- [ ] Install ESLint dependencies
- [ ] Create `.eslintrc.json` configuration
- [ ] Create `.eslintignore` file
- [ ] Add ESLint scripts to package.json
- [ ] Run initial lint check
- [ ] Document baseline violations

### **Step 2: Prettier Setup** 🚧
- [ ] Install Prettier dependencies
- [ ] Create `.prettierrc.json` configuration
- [ ] Create `.prettierignore` file
- [ ] Add Prettier scripts to package.json
- [ ] Integrate with ESLint
- [ ] Run format check
- [ ] Apply auto-formatting

### **Step 3: Stylelint Setup** 🚧
- [ ] Install Stylelint dependencies
- [ ] Create `.stylelintrc.json` configuration
- [ ] Create `.stylelintignore` file
- [ ] Add Stylelint scripts to package.json
- [ ] Run initial lint check
- [ ] Document baseline violations
- [ ] Fix auto-fixable issues

### **Step 4: Pre-commit Hooks** 🚧
- [ ] Install Husky and lint-staged
- [ ] Configure lint-staged
- [ ] Create pre-commit hook
- [ ] Test hook functionality
- [ ] Update team documentation

### **Step 5: Cleanup & Documentation** 🚧
- [ ] Run all linters
- [ ] Fix critical violations
- [ ] Generate linting reports
- [ ] Update development documentation
- [ ] Create linting guidelines for team

---

## 🎯 **Success Criteria**

| Metric | Target | Status |
|--------|--------|--------|
| **ESLint Configured** | Yes | 🚧 **TBD** |
| **Prettier Configured** | Yes | 🚧 **TBD** |
| **Stylelint Configured** | Yes | 🚧 **TBD** |
| **Pre-commit Hooks** | Working | 🚧 **TBD** |
| **Auto-fix Rate** | 80%+ | 🚧 **TBD** |
| **Documentation** | Complete | 🚧 **TBD** |

---

## 📈 **Expected Impact**

### **Code Quality**
- ✅ Consistent code style across team
- ✅ Catch errors before runtime
- ✅ Enforce best practices
- ✅ Reduce code review time

### **Developer Experience**
- ✅ Auto-formatting on save
- ✅ Immediate feedback in editor
- ✅ Reduced merge conflicts
- ✅ Faster onboarding for new developers

### **Maintainability**
- ✅ Easier to read and understand code
- ✅ Consistent patterns across codebase
- ✅ Better IDE support
- ✅ Reduced technical debt

---

## 🧪 **Testing Strategy**

### **Linting Tests**
Since linting is a development tool, we'll verify it works through:

1. **Configuration Validation**
   - ESLint config loads without errors
   - Prettier config is valid
   - Stylelint config is valid

2. **Script Execution**
   - `yarn lint:js` runs successfully
   - `yarn lint:css` runs successfully
   - `yarn format` runs successfully

3. **Pre-commit Hook**
   - Hook triggers on commit
   - Linting runs on staged files
   - Commit blocked if linting fails

4. **Integration with CI/CD** (Future)
   - Add linting to CI pipeline
   - Block PRs with linting errors
   - Generate linting reports

### **Test Files**
We'll create test files to verify linters catch issues:

**File**: `test/frontend/linting_test.js` (Node test)
- Test ESLint catches common issues
- Test Prettier formats correctly
- Test Stylelint catches CSS issues

---

## 💡 **Key Considerations**

### **Rails + esbuild Integration**
- ESLint must understand Rails asset pipeline
- No conflicts with esbuild bundling
- Proper import resolution for modules

### **Bootstrap 5 Compatibility**
- Stylelint rules compatible with Bootstrap SCSS
- Allow Bootstrap variable overrides
- No conflicts with Bootstrap utilities

### **Team Workflow**
- Non-breaking introduction (warnings first)
- Gradual enforcement (fix critical first)
- Clear documentation for team
- Editor integration guides (VS Code, RubyMine)

### **Performance**
- Fast linting (< 5 seconds for full codebase)
- Incremental linting (only changed files)
- Efficient pre-commit hooks

---

## 📋 **Files to Create**

### **Configuration Files**
1. ✅ `.eslintrc.json` - ESLint configuration
2. ✅ `.eslintignore` - ESLint ignore patterns
3. ✅ `.prettierrc.json` - Prettier configuration
4. ✅ `.prettierignore` - Prettier ignore patterns
5. ✅ `.stylelintrc.json` - Stylelint configuration
6. ✅ `.stylelintignore` - Stylelint ignore patterns
7. ✅ `.lintstagedrc.json` - lint-staged configuration
8. ✅ `.husky/pre-commit` - Pre-commit hook

### **Documentation Files**
1. ✅ `docs/frontend/linting-implementation-plan.md` - This document
2. 🚧 `docs/frontend/linting-guide.md` - Team usage guide
3. 🚧 `docs/frontend/linting-summary.md` - Completion summary

### **Test Files**
1. 🚧 `test/frontend/linting_test.js` - Linting verification tests

---

## 🚀 **Next Steps**

1. **Install ESLint** - Setup JavaScript linting
2. **Configure Prettier** - Setup code formatting
3. **Install Stylelint** - Setup CSS/SCSS linting
4. **Setup Pre-commit Hooks** - Automate enforcement
5. **Run Initial Linting** - Identify baseline issues
6. **Fix Auto-fixable Issues** - Clean up codebase
7. **Document Remaining Issues** - Create action plan
8. **Update Team Docs** - Guide for developers

---

**Status**: 🚧 **PLAN COMPLETE - READY FOR IMPLEMENTATION**  
**Estimated Time**: 2-3 hours  
**Risk Level**: LOW (non-breaking, gradual enforcement)

🎯 **Ready to proceed with implementation!**
