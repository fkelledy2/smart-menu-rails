# Inline CSS Remediation Plan

This plan enumerates remaining inline `style="..."` occurrences in html.erb files, with suggested replacements. Where an exact existing utility is unavailable, a proposed new utility is indicated.

Legend
- Replace with: existing Bootstrap or our utilities in `app/assets/stylesheets/components/_utilities.scss`
- Propose: add a new utility in `_utilities.scss` and replace usages

## smartmenus

- app/views/smartmenus/_welcome_banner.html.erb
  - L68: `style="display: none;"` → Replace with: `class="d-none"`

- app/views/smartmenus/_showAllergyns.erb
  - L2: `style="padding-top:20px"` → Replace with: `class="padding-top-lg"`
  - L10: `style='white-space:nowrap'` → Propose: `.whitespace-nowrap { white-space: nowrap; }`

- app/views/smartmenus/_showContext.erb
  - L2,4,5,8,11,14,16,20,23: `style='display:none'` → Replace with: `class="d-none"`

- app/views/smartmenus/_showMenuitemHorizontal.erb
  - L4: `style='padding:5px'` → Replace with: `class="padding-top-xs padding-bottom-sm padding-left-sm padding-right-sm"` (or add `.padding-5`)
  - L36: `style=''` → Remove inline style
  - L37: `style='padding-left:5px; padding-top:5px;padding-right:5px;'` → Replace with utilities: `padding-left-sm padding-top-xs padding-right-sm` (or add `.padding-5`)
  - L64: `style='padding-left:10px;padding-right:10px;padding-top:5px'` → Replace with: `padding-left-md padding-right-md padding-top-xs`

- app/views/smartmenus/_orderStaff.erb
  - L17,23,42: `style='display:none'` → Replace with: `class="d-none"`

- app/views/smartmenus/_showTableLocaleSelectorStaff.erb
  - L2: `style="border-radius: 0px 0 8px 8px;"` → Propose: `.br-0-0-8-8 { border-radius: 0 0 8px 8px; }`
  - L9: `style="z-index: 1050; --bs-dropdown-padding-y: 0.5rem;"` → Replace with: `class="z-index-1000"` and Propose: `.dropdown-padding-y-05` (or leave CSS var inline if necessary)

- app/views/smartmenus/_showMenuContentStaff.erb
  - L4: `style="padding-top:20px"` → `class="padding-top-lg"`
  - L9: `style="height: 150px"` → Replace with: `class="height-150"`
  - L32: `style="width: 140px;"` (input-group) → Propose: `.w-140px { width: 140px; }`

- app/views/smartmenus/_showMenuContentCustomer.erb
  - Similar occurrences of `padding-top:20px`, card images with fixed height, and fixed width input-groups
  - Replace with: `padding-top-lg`, `height-150`, and Propose: `.w-140px`

- app/views/smartmenus/_showModals.erb
  - Multiple `style` in modal bodies/footers previously; we standardized many, but remaining image placeholders may have inline `style="visibility: visible;"`
  - Suggest: manage visibility via classes (e.g., `.visible` / `.invisible`)

- app/views/smartmenus/_showTableLocaleSelectorCustomer.erb
  - Inline styles on dropdowns similar to staff → see staff suggestions

- app/views/smartmenus/_allergen_legend_modal.html.erb
  - Check for `style` in legends; replace padding/margins with utilities.

- app/views/smartmenus/_orderCustomer.erb, _showMenuitem.erb, _showMenuitemHorizontal.erb
  - Replace any `display:none` with `d-none`, paddings with utilities as above.

## menus

- app/views/menus/_form.html.erb
  - L6: `style='display:none'` → `class="d-none"`

- app/views/menus/index_2025_example.html.erb
  - L79: `style="z-index: 1000;"` → `class="z-index-1000"`

- app/views/menus/edit_2025.html.erb
  - L142: `style="z-index: 7000;"` → Propose: `.z-index-7000 { z-index: 7000; }`
  - L143: `style="z-index: 7001; position: fixed; bottom: 0; left: 0; right: 0; margin: 0; width: 100%; max-width: 100%;"`
    - Propose utilities:
      - `.z-index-7001`, `.position-fixed`, `.bottom-0`, `.left-0`, `.right-0`, `.m-0`, `.width-full`, `.max-width-100`
  - L153: `style="display:none;"` → `class="d-none"`
  - L159: `style="width: 0%"` (progress bar) → keep inline (dynamic) or bind width via class with CSS var.
  - L161: `style="display:none;"` → `class="d-none"`

- app/views/menus/sections/_sections_2025.html.erb
  - L60: `style="width: 40px;"` → Propose: `.w-40px`
  - L75: `style="width: 40px; cursor: grab;"` → Propose: `.w-40px` and add utility `.cursor-grab { cursor: grab; }`
  - L99: `style="font-size: 4rem;"` → Replace with: `class="text-extra-large"`

- app/views/menus/sections/_items_2025.html.erb
  - L64: `style="width: 40px;"` → `.w-40px`
  - L117: `style="width: 40px; cursor: grab;"` → `.w-40px cursor-grab`
  - L125: `style="font-size: 14px;"` → Propose: `.text-14px { font-size: 14px; }`
  - L185: `style="font-size: 4rem;"` → `text-extra-large`

- app/views/menus/sections/_qrcode_2025.html.erb
  - L56–59: `style="display: none;"` on hidden data → `class="d-none"`

- app/views/menus/sections/_design_2025.html.erb
  - L104: `style="font-size: 3rem;"` → Propose: `.text-3rem { font-size: 3rem; }`

- app/views/menus/sections/_schedule_2025.html.erb
  - L47: `style="opacity: 0; transition: opacity 0.3s ease;"` → Propose: `.opacity-0` and `.transition-opacity-300`

- app/views/menus/sections/_settings_2025.html.erb
  - L176: `style="font-size: 1.5rem;"` → Propose: `.text-1_5rem { font-size: 1.5rem; }`

## restaurants

- app/views/restaurants/_showTrack.erb
  - Several inline `style` attributes (check positioning/sizing); replace with utilities (`position-*`, spacing, `z-index-*`).

- app/views/restaurants/_showSmartMenus.html.erb
  - Verify and replace inline `style` occurrences with utilities (`d-none`, `z-index-*`, spacing).

- app/views/restaurants/_sidebar_2025.html.erb
  - Any inline font-size → map to `.text-*` utilities.

- app/views/restaurants/edit_2025.html.erb
  - Any inline `style` → utilities as above.

- app/views/restaurants/sections/_address_2025.html.erb
  - Multiple inline styles (layout/sizing). Replace with grid classes/spacing utilities.

- app/views/restaurants/sections/_details_2025.html.erb
  - Multiple inline styles. Replace with utilities (`padding-*`, `margin-*`, font-size utilities).

- app/views/restaurants/sections/_hours_2025.html.erb, _import_2025.html.erb, _jukebox_2025.html.erb,
  _localization_2025.html.erb, _menus_2025.html.erb, _ordering_2025.html.erb, _settings_2025.html.erb, _staff_2025.html.erb, _tables_2025.html.erb
  - Replace display/spacing/font-size inline styles with utilities per pattern above.

## onboarding

- app/views/onboarding/show.html.erb
  - L19: `style="width: <%= @progress %>%"` (dynamic) → keep inline or refactor to CSS var.

## ocr_menu_imports

- app/views/ocr_menu_imports/show.html.erb
  - Some inline styles remain in progress/preview areas; consider CSS classes if not dynamic.

## shared

- app/views/shared/_resource_list_2025.html.erb
  - Check for any remaining inline styles; convert to utilities.

## hero_images, application, tracks, menuitems

- app/views/application/offline.html.erb
  - L166: `style="display: none;"` → `class="d-none"`

- app/views/hero_images/index.html.erb, show.html.erb
  - Replace any inline sizing (font-size) with utilities.

- app/views/tracks/_showTrack.erb
  - Replace inline styles with utilities (`position-*`, spacing, `z-index-*`).

- app/views/menuitems/_form.html.erb
  - L28: `style="display:none"` → `class="d-none"`

---

## Proposed new utilities (to add in _utilities.scss)
- `.w-40px { width: 40px; }`
- `.w-140px { width: 140px; }`
- `.cursor-grab { cursor: grab; }`
- `.text-14px { font-size: 14px; }`
- `.text-3rem { font-size: 3rem; }`
- `.text-1_5rem { font-size: 1.5rem; }`
- `.br-0-0-8-8 { border-radius: 0 0 8px 8px; }`
- `.opacity-0 { opacity: 0; }`
- `.transition-opacity-300 { transition: opacity 0.3s ease; }`
- (Optionally) `.visible { visibility: visible; }` / `.invisible { visibility: hidden; }`

We can execute this remediation in batches (e.g., smartmenus/, menus/, restaurants/) and add the new utilities as needed. Let me know which folder to start converting and I’ll implement the changes. 
