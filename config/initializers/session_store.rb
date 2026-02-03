# Configure session store
Rails.application.config.session_store :cookie_store, 
  key: '_smart_menu_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  expire_after: 14.days
