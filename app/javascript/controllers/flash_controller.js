import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this.element.querySelectorAll('.toast').forEach((el) => {
      const toast = new bootstrap.Toast(el, { autohide: true, delay: 4000 });
      toast.show();
    });
  }
}
