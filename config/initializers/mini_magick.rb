# Constrain ImageMagick resource usage to prevent pixel-cache exhaustion on Heroku dynos.
# The "cache resources exhausted" error occurs when ImageMagick tries to allocate more memory
# than the system allows. Setting explicit limits keeps PDF rendering within dyno memory budgets.
MiniMagick.configure do |config|
  # Use the CLI (convert) rather than the GraphicsMagick variant
  config.cli = :imagemagick

  # Append resource limits to every convert invocation
  config.cli_options = [
    '-limit', 'memory', '128MB',
    '-limit', 'map',    '256MB',
    '-limit', 'disk',   '512MB',
    '-limit', 'thread', '1',
  ]
end
