// Import Stimulus application
import { application } from "./application"

// Import and register controllers
import SortableController from "./sortable_controller"
import AutoSaveController from "./auto_save_controller"
import MenuImportController from "./menu_import_controller"
import SidebarController from "./sidebar_controller"
import HelloController from "./hello_controller"
import OcrUploadController from "./ocr_upload_controller"
import StripeWalletController from "./stripe_wallet_controller"
import StateController from "./state_controller"
import OrderHeaderController from "./order_header_controller"
import OrderTotalsController from "./order_totals_controller"
import OrderingController from "./ordering_controller"
import LocalizationBulkController from "./localization_bulk_controller"
import MenuitemsBulkController from "./menuitems_bulk_controller"
import MenusectionsBulkController from "./menusections_bulk_controller"
import RestaurantsBulkController from "./restaurants_bulk_controller"
import DiscoveredRestaurantDeepDiveController from "./discovered_restaurant_deep_dive_controller"
import DiscoveredRestaurantWebScrapeController from "./discovered_restaurant_web_scrape_controller"
import RestaurantmenusBulkController from "./restaurantmenus_bulk_controller"
import DiscoveredRestaurantsBulkController from "./discovered_restaurants_bulk_controller"
import PasswordConfirmationToggleController from "./password_confirmation_toggle_controller"
import DisabledActionController from "./disabled_action_controller"
import UserplanPlanChangeController from "./userplan_plan_change_controller"
import GoLiveProgressController from "./go_live_progress_controller"
import SettingsDependenciesController from "./settings_dependencies_controller"
import BottomSheetController from "./bottom_sheet_controller"
import TabBarController from "./tab_bar_controller"
import MenuLayoutController from "./menu_layout_controller"
import InlineEditController from "./inline_edit_controller"
import MobileTabBarController from "./mobile_tab_bar_controller"
import AiImageGeneratorController from "./ai_image_generator_controller"
import ScrollspyController from "./scrollspy_controller"
import SommelierController from "./sommelier_controller"
import GeneratePairingsController from "./generate_pairings_controller"
import WelcomeBannerController from "./welcome_banner_controller"
import AiProgressController from "./ai_progress_controller"
import WhiskeyAmbassadorController from "./whiskey_ambassador_controller"
import CartBadgeController from "./cart_badge_controller"
import LazyStripeController from "./lazy_stripe_controller"
import InviteStaffController from "./invite_staff_controller"
import CameraCaptureController from "./camera_capture_controller"

application.register("sortable", SortableController)
application.register("auto-save", AutoSaveController)
application.register("menu-import", MenuImportController)
application.register("sidebar", SidebarController)
application.register("hello", HelloController)
application.register("ocr-upload", OcrUploadController)
application.register("stripe-wallet", StripeWalletController)
application.register("state", StateController)
application.register("order-header", OrderHeaderController)
application.register("order-totals", OrderTotalsController)
application.register("ordering", OrderingController)
application.register("localization-bulk", LocalizationBulkController)
application.register("menuitems-bulk", MenuitemsBulkController)
application.register("menusections-bulk", MenusectionsBulkController)
application.register("restaurants-bulk", RestaurantsBulkController)
application.register("discovered-restaurant-deep-dive", DiscoveredRestaurantDeepDiveController)
application.register("discovered-restaurant-web-scrape", DiscoveredRestaurantWebScrapeController)
application.register("restaurantmenus-bulk", RestaurantmenusBulkController)
application.register("discovered-restaurants-bulk", DiscoveredRestaurantsBulkController)
application.register("password-confirmation-toggle", PasswordConfirmationToggleController)
application.register("disabled-action", DisabledActionController)
application.register("userplan-plan-change", UserplanPlanChangeController)
application.register("go-live-progress", GoLiveProgressController)
application.register("settings-dependencies", SettingsDependenciesController)
application.register("bottom-sheet", BottomSheetController)
application.register("tab-bar", TabBarController)
application.register("menu-layout", MenuLayoutController)
application.register("inline-edit", InlineEditController)
application.register("mobile-tab-bar", MobileTabBarController)
application.register("ai-image-generator", AiImageGeneratorController)
application.register("scrollspy", ScrollspyController)
application.register("sommelier", SommelierController)
application.register("generate-pairings", GeneratePairingsController)
application.register("welcome-banner", WelcomeBannerController)
application.register("ai-progress", AiProgressController)
application.register("whiskey-ambassador", WhiskeyAmbassadorController)
application.register("cart-badge", CartBadgeController)
application.register("lazy-stripe", LazyStripeController)
application.register("invite-staff", InviteStaffController)
application.register("camera-capture", CameraCaptureController)

console.log('[Stimulus] Controllers registered:', ['sortable', 'auto-save', 'menu-import', 'sidebar', 'hello', 'ocr-upload', 'stripe-wallet', 'state', 'order-header', 'order-totals', 'ordering', 'localization-bulk', 'menuitems-bulk', 'menusections-bulk', 'restaurants-bulk', 'discovered-restaurant-deep-dive', 'discovered-restaurant-web-scrape', 'restaurantmenus-bulk', 'discovered-restaurants-bulk', 'password-confirmation-toggle', 'disabled-action', 'userplan-plan-change', 'go-live-progress', 'settings-dependencies', 'bottom-sheet', 'tab-bar', 'menu-layout', 'inline-edit', 'mobile-tab-bar', 'ai-image-generator', 'scrollspy', 'generate-pairings', 'welcome-banner', 'ai-progress', 'whiskey-ambassador', 'cart-badge', 'lazy-stripe', 'invite-staff', 'camera-capture'])
