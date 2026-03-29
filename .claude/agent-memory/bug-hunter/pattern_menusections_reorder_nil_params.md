---
name: MenusectionsController#reorder crashes on missing params[:order]
description: reorder calls params[:order].each without checking if params[:order] is present — NoMethodError on nil if param is missing
type: project
---

`app/controllers/menusections_controller.rb` line 153:
```ruby
params[:order].each do |item|
```
If the request body omits `order`, `params[:order]` is nil and `.each` raises NoMethodError. The `rescue StandardError` at the bottom does catch it, but it renders a 422 with a confusing `e.message` instead of a proper 400.

**Why:** No guard before iterating `params[:order]`.

**How to apply:**
```ruby
unless params[:order].is_a?(Array)
  render json: { status: 'error', message: 'order param required' }, status: :bad_request
  return
end
```
