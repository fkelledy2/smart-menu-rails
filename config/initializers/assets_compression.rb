# Disable CSS compression to avoid SassC errors with modern CSS syntax
# Modern CSS features like min(), max(), rgb() with space-separated values
# are not supported by SassC compressor
Rails.application.config.assets.css_compressor = nil
