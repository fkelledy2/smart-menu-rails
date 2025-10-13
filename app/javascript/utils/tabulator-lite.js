/**
 * Tabulator Lite - Custom build with only essential features
 * Reduces bundle size by excluding unused modules
 */

// Import only the core Tabulator modules we actually use
import { Tabulator } from 'tabulator-tables/src/js/core/Tabulator.js'

// Essential modules only
import 'tabulator-tables/src/js/modules/Edit/Edit.js'
import 'tabulator-tables/src/js/modules/Filter/Filter.js'
import 'tabulator-tables/src/js/modules/Sort/Sort.js'
import 'tabulator-tables/src/js/modules/Format/Format.js'
import 'tabulator-tables/src/js/modules/ResizeColumns/ResizeColumns.js'
import 'tabulator-tables/src/js/modules/ResponsiveLayout/ResponsiveLayout.js'
import 'tabulator-tables/src/js/modules/Persistence/Persistence.js'

// Essential formatters only
import 'tabulator-tables/src/js/modules/Format/defaults/formatters/money.js'
import 'tabulator-tables/src/js/modules/Format/defaults/formatters/datetime.js'
import 'tabulator-tables/src/js/modules/Format/defaults/formatters/plaintext.js'

// Essential editors only
import 'tabulator-tables/src/js/modules/Edit/defaults/editors/input.js'
import 'tabulator-tables/src/js/modules/Edit/defaults/editors/textarea.js'
import 'tabulator-tables/src/js/modules/Edit/defaults/editors/select.js'
import 'tabulator-tables/src/js/modules/Edit/defaults/editors/number.js'

// Skip heavy modules we don't use:
// - Download (CSV/PDF export) - can be done server-side
// - Clipboard - not essential
// - GroupRows - not used
// - Menu - not used
// - Popup - not used
// - Print - not used
// - SelectRow - basic selection is enough
// - MoveColumns - not used
// - MoveRows - not used
// - History - not essential
// - Keybindings - not used
// - Ajax - we handle data loading
// - HTML import/export - not used
// - Interaction - basic is enough
// - Tooltip - not essential
// - Validate - can be done elsewhere

export { Tabulator as TabulatorLite }
export default Tabulator
