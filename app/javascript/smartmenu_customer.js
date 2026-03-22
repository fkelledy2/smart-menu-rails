// Customer Bundle - Optimized (No jQuery)
import '@hotwired/turbo-rails';
import { Application } from '@hotwired/stimulus';
import * as bootstrap from 'bootstrap';
import './sentry';
import './channels/ordr_channel';
import { initOrderBindings } from './ordr_commons';

window.bootstrap = bootstrap;
const app = Application.start();
window.Stimulus = app;

// Lazy load only customer controllers
Promise.all([
  import('./controllers/bottom_sheet_controller'),
  import('./controllers/menu_layout_controller'),
  import('./controllers/menu_search_controller'),
  import('./controllers/state_controller'),
  import('./controllers/order_header_controller'),
  import('./controllers/scrollspy_controller'),
  import('./controllers/theme_toggle_controller'),
  import('./controllers/allergen_filter_controller'),
]).then(([bs, ml, ms, st, oh, sp, tt, af]) => {
  app.register('bottom-sheet', bs.default);
  app.register('menu-layout', ml.default);
  app.register('menu-search', ms.default);
  app.register('state', st.default);
  app.register('order-header', oh.default);
  app.register('scrollspy', sp.default);
  app.register('theme-toggle', tt.default);
  app.register('allergen-filter', af.default);
  initOrderBindings();
  console.log('[Customer] Ready');
});
