# Pin npm packages by running ./bin/importmap

# Pin npm packages
pin 'jquery', to: 'https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js'
pin 'jquery_ujs', to: 'https://ga.jspm.io/npm:jquery-ujs@1.2.3/src/rails.js'
pin 'bootstrap', to: 'https://ga.jspm.io/npm:bootstrap@5.3.0/dist/js/bootstrap.esm.js'
pin '@popperjs/core', to: 'https://ga.jspm.io/npm:@popperjs/core@2.11.8/dist/esm/index.js'
pin '@hotwired/turbo-rails', to: 'https://cdn.skypack.dev/@hotwired/turbo-rails'
pin '@hotwired/stimulus', to: 'https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js'
# pin "@hotwired/stimulus-loading", to: "app/javascript/stimulus-loading.js"
# Rails libraries - using local asset pipeline to avoid CDN version issues
pin "@rails/actioncable", to: "actioncable.esm.js", preload: true
pin "@rails/actiontext", to: "actiontext.js", preload: true  
pin "trix", preload: true
pin "@rails/activestorage", to: "activestorage.esm.js", preload: true

# Pin external dependencies for new system (reliable CDN strategy)
pin 'tom-select', to: 'https://cdn.skypack.dev/tom-select', preload: true
pin 'tabulator-tables', to: 'https://cdn.skypack.dev/tabulator-tables', preload: true
pin 'local-time', to: 'https://cdn.skypack.dev/local-time', preload: true
pin 'luxon', to: 'https://cdn.skypack.dev/luxon', preload: true

# Pin application JavaScript (used by ALL controllers)
pin 'application', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin_all_from 'app/javascript/channels', under: 'channels'

# Pin local JavaScript files
pin_all_from 'app/javascript/custom', under: 'custom'

