---
name: API V1 menus/items dietary NoMethodError
description: V1 menus and menu_items controllers call allergens/vegetarian?/vegan?/gluten_free? on Menuitem — those columns only exist on OcrMenuItem
type: project
---

`app/controllers/api/v1/menus_controller.rb` lines 118–122 and `app/controllers/api/v1/menu_items_controller.rb` lines 33–37 call `item.allergens`, `item.vegetarian?`, `item.vegan?`, `item.gluten_free?` on `Menuitem` objects.

These columns (`allergens`, `is_vegetarian`, `is_vegan`, `is_gluten_free`) exist only on the `ocr_menu_items` table / `OcrMenuItem` model. The `menuitems` table has none of them.

Every `GET /api/v1/menus/:id` and `GET /api/v1/menus/:menu_id/items` request raises `NoMethodError` → 500.

**Why:** Dietary serialization logic was copy-pasted from OcrMenuItem serialization into the Menuitem API serializer without verifying column existence.

**How to apply:** When investigating 500s on V1 menu endpoints, check the serializer helper methods for OcrMenuItem-specific method calls. Also a pattern to watch: methods that exist on OCR models being assumed to exist on core menu models.
