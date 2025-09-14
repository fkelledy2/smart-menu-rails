# Pin npm packages by running ./bin/importmap

# Pin npm packages
pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js"
pin "jquery_ujs", to: "https://ga.jspm.io/npm:jquery-ujs@1.2.3/src/rails.js"
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.3.0/dist/js/bootstrap.esm.js"
pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/dist/esm/index.js"
pin "@hotwired/turbo-rails", to: "https://ga.jspm.io/npm:@hotwired/turbo-rails@8.0.0-rc.2/app/javascript/turbo/index.js"
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js"
# pin "@hotwired/stimulus-loading", to: "app/javascript/stimulus-loading.js"
pin "@rails/actioncable", to: "https://cdn.jsdelivr.net/npm/@rails/actioncable@7.1.3-2/app/assets/javascripts/actioncable.esm.js"
pin "@rails/actiontext", to: "https://cdn.jsdelivr.net/npm/@rails/actiontext@7.1.3-2/app/assets/javascripts/actiontext.js"
pin "trix"
pin "@rails/activestorage", to: "https://cdn.jsdelivr.net/npm/@rails/activestorage@7.1.3-2/app/assets/javascripts/activestorage.esm.js"

# Pin application JavaScript
pin "application", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/channels", under: "channels"

# Pin local JavaScript files
pin_all_from "app/javascript/custom", under: "custom"
