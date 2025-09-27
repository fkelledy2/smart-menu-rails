require 'rspotify'

# Only attempt app-level authentication at boot if explicitly enabled and credentials are present.
spotify_key = Rails.application.credentials.spotify_key
spotify_secret = Rails.application.credentials.spotify_secret

if spotify_key.present? && spotify_secret.present?
  if ENV['SPOTIFY_AUTH_AT_BOOT'] == 'true'
    begin
      RSpotify::authenticate(spotify_key, spotify_secret)
      Rails.logger.info('[rspotify] App authentication succeeded at boot')
    rescue => e
      Rails.logger.warn("[rspotify] App authentication skipped due to error: #{e.class}: #{e.message}")
    end
  else
    Rails.logger.info('[rspotify] Skipping app authentication at boot (set SPOTIFY_AUTH_AT_BOOT=true to enable)')
  end
else
  Rails.logger.info('[rspotify] Spotify credentials missing; skipping app authentication at boot')
end
