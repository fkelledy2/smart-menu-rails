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

console.log('[Stimulus] Controllers registered:', ['sortable', 'auto-save', 'menu-import', 'sidebar', 'hello', 'ocr-upload', 'stripe-wallet', 'state', 'order-header', 'order-totals'])
