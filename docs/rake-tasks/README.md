# Rake Tasks Documentation

This folder contains documentation for Rake tasks, including usage, implementation details, and updates.

## Contents

### Image Generation
- **MENU_IMAGES_GENERATE_ALL_UPDATE.md** - AI image generation task with Genimage pre-check

### Catalog Management
- **CATALOG_RESOURCES_UPDATE.md** - Catalog resources update task

## Available Tasks

To see all available rake tasks:
```bash
bundle exec rake -T
```

### Common Tasks

**Menu Item Processing:**
```bash
# Create Genimage records for all menu items
bundle exec rake menuitems:reprocess

# Generate AI images for all menu items (includes Genimage check)
bundle exec rake menu_images:generate_all

# Generate images for specific menu
bundle exec rake menu_images:generate_all[16]
```

**Database Tasks:**
```bash
# Various database maintenance tasks
bundle exec rake db:migrate
bundle exec rake db:seed
```

## Task Documentation Format

Each task document includes:
1. **Overview** - What the task does
2. **Usage** - Command syntax and options
3. **Implementation** - Technical details
4. **Examples** - Sample output
5. **Related Tasks** - Connected rake tasks

## Task Location

Rake tasks are defined in: `lib/tasks/`

## Related Documentation
- `/database` - Database-related tasks
- `/performance` - Performance optimization tasks
