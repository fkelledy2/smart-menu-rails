import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  submit(event) {
    if (event.key === 'Enter') {
      event.preventDefault();
      this.element.closest('form').requestSubmit();
    }
  }
}
