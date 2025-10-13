// Admin-specific functionality
import '../modules/employees/EmployeeModule.js'
import '../modules/analytics/AnalyticsModule.js'
import '../modules/restaurants/RestaurantModule.js'

// Admin-specific libraries (only load when needed)
let Tabulator = null

// Lazy load Tabulator only when tables are present
if (document.querySelector('[data-tabulator]')) {
  import('tabulator-tables').then(({ TabulatorFull }) => {
    Tabulator = TabulatorFull
    window.Tabulator = Tabulator
    console.log('[SmartMenu] Tabulator loaded for admin')
  })
}

console.log('[SmartMenu] Admin bundle loaded')