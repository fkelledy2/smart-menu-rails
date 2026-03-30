# Smartmenu Theming — User Guide

## Overview

Smartmenu Theming lets you choose a visual style for your customer-facing digital menu from four curated designs: Classic, Modern, Rustic, and Elegant. Each theme changes the fonts, colours, card shapes, spacing, and overall feel of the menu your customers see. You can preview any theme before saving, and changes take effect immediately for all customers without any page reloads on their end.

## Who This Is For

Restaurant owners and managers with permission to edit the restaurant's menu settings.

## Prerequisites

- You must have owner or manager access to the restaurant.
- The `smartmenu_theming` Flipper feature flag must be enabled for your restaurant. Contact mellow.menu support to enable it.
- Themes are set per Smartmenu, not per restaurant. If your restaurant has multiple menus (e.g., a lunch menu and a dinner menu), you can set a different theme for each.

## How To Use

### Choosing and Previewing a Theme

1. Sign in to your restaurant dashboard.
2. Go to **Menu** and select the menu you want to theme.
3. Click **Edit** to open the menu edit page.
4. Look for the **Theme** section in the settings panel (usually in the sidebar or settings tab).
5. You will see four theme swatches. Each swatch shows the theme name and a font sample.
6. Click any swatch to select it. Click the **Preview in new tab** button to open your live Smartmenu in a new tab and see how it will look — your customers do not see the change yet (save first to apply it for real).
7. Click through the swatches to compare. Take your time — nothing is saved until you click Save.

### Saving Your Theme

1. Once you have chosen a theme, click **Save** (or the standard save button for the menu edit page).
2. The theme is applied immediately. Any customer viewing your Smartmenu sees the new appearance within moments.

### Switching Themes Later

You can change the theme at any time by returning to the menu edit page and repeating the steps above. There is no limit on how often you can switch themes.

## The Four Themes

**Classic**
The default look — clean, straightforward, and broadly compatible with any restaurant style. A safe starting point if you are unsure.

**Modern**
Minimal and contemporary. Clean lines, a reduced border radius on cards, high-contrast colours, and the Inter typeface. Works well for cafes, casual dining, and fast-casual concepts.

**Rustic**
Warm tones, organic card shapes, textured section dividers, and the Playfair Display typeface. Suits gastropubs, farm-to-table restaurants, and venues with a relaxed, earthy atmosphere.

**Elegant**
Generous whitespace, fine dividers, a restrained colour palette, and the Cormorant Garamond serif typeface. Designed for fine dining, wine bars, and premium experiences where the menu itself should feel like part of the brand.

## Key Concepts

**Smartmenu** — the customer-facing digital menu that customers access by scanning a QR code. Themes are applied to this view, not to the restaurant management interface.

**Theme** — a complete visual profile including colours, typography, card shapes, spacing, and decorative elements. You select from four pre-built options — free-form colour or font customisation is not available in v1.

**Cache bust** — when you save a theme change, the system immediately clears cached copies of your menu pages so that customers see the new theme straight away. You do not need to do anything extra.

**Dark mode** — dark mode and themes are separate, independent settings. Themes control your restaurant's brand look; dark mode responds to the customer's device preference. Both work independently.

## Tips & Best Practices

- Use the preview panel to compare themes side-by-side before committing. Cycle through all four to make sure you are choosing the right fit.
- Match the theme to your physical environment. Customers who sit down at a candlelit, white-tablecloth restaurant and then open a Modern-themed digital menu may find the contrast jarring.
- You can change themes seasonally — for example, switching to Rustic for autumn specials or Elegant for a festive menu.
- Theme changes are instant. Consider making significant theme changes during quieter periods to avoid surprising customers mid-service.

## Limitations & Known Constraints

- Only four themes are available in v1. Custom colour pickers or free-form font choices are not supported.
- Themes apply to the entire Smartmenu. You cannot apply different themes to individual sections or items.
- Dark mode variants of each theme (e.g., "Dark Rustic") are not available. Dark mode uses a single overlay that works across all themes.
- Theme scheduling (apply Theme A at lunch, Theme B at dinner) is not supported.
- Fonts are loaded from Google Fonts via CDN. Customers with restricted internet access may see a fallback font.

## Frequently Asked Questions

**Q: Will changing my theme affect customers who are currently using the menu?**
A: The new theme takes effect for all customers as soon as you save. Customers already on the page will see the new theme when the page next renders (usually within moments, or on their next interaction).

**Q: Can I preview a theme without my customers seeing the change?**
A: Yes. Select a swatch to highlight your choice, then click **Preview in new tab**. This opens the live Smartmenu in a new browser tab so you can see what the theme looks like. Customers only see the change after you save. Note: the preview shows the last saved theme — save first, then preview, for the most accurate view.

**Q: Why does the preview look slightly different from the editor?**
A: The preview opens your live Smartmenu in a new tab — the most accurate view of how customers will see the theme. Small differences in the editor are due to the reduced panel size.

**Q: My restaurant has two menus — a lunch menu and a dinner menu. Can they have different themes?**
A: Yes. Themes are set per Smartmenu, so you can give each menu its own look.

**Q: The theme picker is not visible on my menu edit page. What do I do?**
A: The theme picker requires the `smartmenu_theming` feature flag to be enabled for your restaurant. Contact mellow.menu support to request access.
