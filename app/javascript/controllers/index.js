// Import Stimulus application
import { application } from "./application"

// Import and register controllers
import SortableController from "./sortable_controller"
import AutoSaveController from "./auto_save_controller"
import MenuImportController from "./menu_import_controller"
import SidebarController from "./sidebar_controller"
import HelloController from "./hello_controller"

application.register("sortable", SortableController)
application.register("auto-save", AutoSaveController)
application.register("menu-import", MenuImportController)
application.register("sidebar", SidebarController)
application.register("hello", HelloController)

console.log('[Stimulus] Controllers registered:', ['sortable', 'auto-save', 'menu-import', 'sidebar', 'hello'])
