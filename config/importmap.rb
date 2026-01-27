# Pin npm packages by running ./bin/importmap

# Pin npm packages
pin 'jquery', to: 'https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js'
pin 'jquery_ujs', to: 'https://ga.jspm.io/npm:jquery-ujs@1.2.3/src/rails.js'
pin 'bootstrap', to: 'https://ga.jspm.io/npm:bootstrap@5.3.0/dist/js/bootstrap.esm.js'
pin '@popperjs/core', to: 'https://ga.jspm.io/npm:@popperjs/core@2.11.8/dist/esm/index.js'
pin '@hotwired/stimulus', to: 'https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js'
# pin "@hotwired/stimulus-loading", to: "app/javascript/stimulus-loading.js"
# Rails libraries - using local asset pipeline to avoid CDN version issues
pin '@rails/actioncable', to: 'actioncable.esm.js', preload: true
pin '@rails/actiontext', to: 'actiontext.js', preload: true
pin 'trix', preload: true
pin '@rails/activestorage', to: 'activestorage.esm.js', preload: true

# Pin external dependencies for new system (reliable CDN strategy)
pin 'qr-code-styling', to: 'https://cdn.jsdelivr.net/npm/qr-code-styling@1.6.0-rc.1/lib/qr-code-styling.js', preload: true

# Pin application JavaScript (used by ALL controllers)
# Cache bust timestamp to force reload: 2025-11-04-19-17
pin 'application', to: 'application.js?v=20251104191700', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin_all_from 'app/javascript/channels', under: 'channels'

# Pin local JavaScript files
pin_all_from 'app/javascript/custom', under: 'custom'

# Pin specific modules (not all, to avoid missing file errors)
pin 'modules/hero_carousel', to: 'modules/hero_carousel.js'
