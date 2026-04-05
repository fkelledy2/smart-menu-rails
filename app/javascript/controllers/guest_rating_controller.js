import { Controller } from '@hotwired/stimulus';

// GuestRatingController handles the 1–5 star rating widget shown after checkout.
// On star selection it reveals a comment textarea and submit button.
// On submit it POSTs to the guest_rating endpoint and shows a thank-you message.
export default class extends Controller {
  static targets = [
    'stars',
    'commentContainer',
    'comment',
    'submitButton',
    'ratingContainer',
    'thankyou',
  ];
  static values = { url: String };

  connect() {
    this._selectedStars = 0;
  }

  setStar(event) {
    const value = parseInt(event.currentTarget.dataset.value, 10);
    this._selectedStars = value;
    this._renderStars(value);
    this.commentContainerTarget.style.display = 'block';
  }

  hoverStar(event) {
    const value = parseInt(event.currentTarget.dataset.value, 10);
    this._renderStars(value, true);
  }

  resetHover() {
    this._renderStars(this._selectedStars || 0);
  }

  async submit() {
    if (!this._selectedStars) return;

    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.textContent = 'Sending…';

    try {
      const body = new FormData();
      body.append('guest_rating[stars]', this._selectedStars);
      body.append('guest_rating[comment]', this.commentTarget.value || '');

      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest', Accept: 'application/json' },
        body,
      });

      if (response.ok) {
        this.ratingContainerTarget.style.display = 'none';
        this.thankyouTarget.style.display = 'block';
      } else {
        this.submitButtonTarget.disabled = false;
        this.submitButtonTarget.textContent = 'Submit';
      }
    } catch (_err) {
      this.submitButtonTarget.disabled = false;
      this.submitButtonTarget.textContent = 'Submit';
    }
  }

  // -------------------------------------------------------------------------
  // Private
  // -------------------------------------------------------------------------
  _renderStars(upTo, hover = false) {
    const stars = this.starsTarget.querySelectorAll('.guest-rating__star');
    stars.forEach((star) => {
      const val = parseInt(star.dataset.value, 10);
      const filled = val <= upTo;
      const icon = star.querySelector('i');
      if (icon) {
        icon.className = filled ? 'bi bi-star-fill' : 'bi bi-star';
      }
      star.style.color = filled ? (hover ? '#FBBF24' : '#F59E0B') : '#D1D5DB';
    });
  }
}
