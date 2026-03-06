---
description: Run the full test suite (Minitest + RSpec)
---

1. Run Minitest unit + integration tests:
// turbo
```bash
bin/rails test
```

2. Run RSpec request + service specs:
// turbo
```bash
bundle exec rspec
```

3. (Optional) Run system tests with Playwright:
```bash
bin/rails test:system
```
