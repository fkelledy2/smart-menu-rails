import { Controller } from '@hotwired/stimulus';

// Tracks engagement events for the embedded demo video.
// Posts events to /demo_bookings/video_analytics via fetch (fire-and-forget).
// Tracks: play, pause, ended, and completion milestones (25/50/75/100%).
export default class extends Controller {
  static targets = ['player'];

  static values = {
    videoId: String, // e.g. "homepage-demo"
    endpoint: String, // /demo_bookings/video_analytics
  };

  // Milestone sentinels — each fires once per video load
  #sentinels = { 25: false, 50: false, 75: false, 100: false };

  connect() {
    this.#sentinels = { 25: false, 50: false, 75: false, 100: false };
  }

  trackPlay() {
    this.#post('play', this.#currentTime());
  }

  trackPause() {
    // Don't fire pause if the video has ended (ended fires separately)
    if (!this.playerTarget.ended) {
      this.#post('pause', this.#currentTime());
    }
  }

  trackEnded() {
    this.#post('ended', this.#currentTime());
  }

  trackProgress() {
    const video = this.playerTarget;
    if (!video.duration) return;

    const pct = (video.currentTime / video.duration) * 100;

    for (const milestone of [25, 50, 75, 100]) {
      if (!this.#sentinels[milestone] && pct >= milestone) {
        this.#sentinels[milestone] = true;
        this.#post(`completion_${milestone}`, Math.round(video.currentTime));
      }
    }
  }

  // -- private helpers --------------------------------------------------------

  #currentTime() {
    return Math.round(this.playerTarget.currentTime || 0);
  }

  #sessionId() {
    // Use existing anonymous session identifier stored in the cookie, or
    // generate a lightweight ephemeral ID for this page load.
    if (!this._sessionId) {
      this._sessionId = `va-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
    }
    return this._sessionId;
  }

  async #post(eventType, timestampSeconds) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    try {
      await fetch(this.endpointValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'X-CSRF-Token': csrfToken || '',
        },
        body: JSON.stringify({
          video_id: this.videoIdValue,
          session_id: this.#sessionId(),
          event_type: eventType,
          timestamp_seconds: timestampSeconds,
        }),
        // Fire-and-forget — don't await or react to the response
        keepalive: true,
      });
    } catch (_err) {
      // Video analytics are non-critical — silently swallow network errors
    }
  }
}
