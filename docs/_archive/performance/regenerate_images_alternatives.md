# Regenerate Images Integration Options

## Current Implementation ✅ **IMPLEMENTED**

The "Regenerate Images" button now uses a `RegenerateImagesJob` that implements the same logic as the rake task but runs asynchronously through Sidekiq.

### Flow:
1. User clicks "Regenerate Images" button
2. Controller calls `RegenerateImagesJob.perform_async(@menu.id)`
3. Job processes all genimages for the menu using the same logic as the rake task
4. Uses `GenerateImageJob.perform_sync` for each image (synchronous within the job)

## Alternative Options

### Option 1: Direct Rake Task Call (Synchronous)
```ruby
def regenerate_images
  authorize @menu, :update?
  
  if @menu.nil?
    redirect_to root_url and return
  end

  # Call rake task directly (blocks the request)
  system("cd #{Rails.root} && bin/rails genimages:update_all[#{@menu.id}]")
  
  flash[:notice] = "Image regeneration completed for this menu."
  redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu)
end
```

**Pros:** Simple, uses existing rake task
**Cons:** Blocks the web request, poor user experience for large menus

### Option 2: Async Rake Task Call
```ruby
def regenerate_images
  authorize @menu, :update?
  
  if @menu.nil?
    redirect_to root_url and return
  end

  # Queue rake task to run in background
  RakeTaskJob.perform_async("genimages:update_all", @menu.id)
  
  flash[:notice] = "Image regeneration has been queued for this menu."
  redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu)
end
```

With a generic `RakeTaskJob`:
```ruby
class RakeTaskJob
  include Sidekiq::Job

  def perform(task_name, *args)
    Rails.logger.info "[RakeTaskJob] Running rake task: #{task_name} with args: #{args}"
    
    # Build the rake command
    cmd = "cd #{Rails.root} && bin/rails #{task_name}"
    cmd += "[#{args.join(',')}]" if args.any?
    
    system(cmd)
  end
end
```

### Option 3: Unified Service Class
Create a service class that both the rake task and controller can use:

```ruby
class ImageRegenerationService
  def self.regenerate_for_menu(menu_id, async: true)
    new(menu_id).regenerate(async: async)
  end

  def initialize(menu_id)
    @menu_id = menu_id
  end

  def regenerate(async: true)
    scope = Genimage.where(menu_id: @menu_id)
    total = scope.count
    
    Rails.logger.info "Processing #{total} genimages for menu_id=#{@menu_id}"
    
    scope.find_each.with_index do |genimage, index|
      next if genimage.menuitem&.itemtype == 'wine'

      if async
        GenerateImageJob.perform_async(genimage.id)
      else
        GenerateImageJob.perform_sync(genimage.id)
      end
      
      sleep(1) if !async && index < total - 1
    end
  end
end
```

Then update both:
- **Rake task:** `ImageRegenerationService.regenerate_for_menu(args[:menu_id], async: false)`
- **Controller:** `ImageRegenerationService.regenerate_for_menu(@menu.id, async: true)`

## Recommendation

The current implementation (Option with `RegenerateImagesJob`) is the best approach because:

1. **Consistency:** Uses the same logic as the rake task
2. **Performance:** Doesn't block the web request
3. **Reliability:** Proper error handling and logging
4. **Flexibility:** Can be monitored through Sidekiq dashboard
5. **Scalability:** Can handle large menus without timeout issues

## Testing

To test the integration:

1. Navigate to `http://localhost:3000/restaurants/1/menus/16/edit`
2. Click "Regenerate Images" button
3. Check Sidekiq dashboard for the queued job
4. Monitor logs for job execution: `tail -f log/development.log | grep RegenerateImagesJob`
