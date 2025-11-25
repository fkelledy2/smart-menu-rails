import { Controller } from '@hotwired/stimulus';

// Controls enabling of the Upload & Process button on the OCR upload page
// Requires:
// - data-controller="ocr-upload" on a container (e.g., the form)
// - data-ocr-upload-target="nameInput" on the menu name input
// - data-ocr-upload-target="fileInput" on the file input (PDF)
// - A submit button with id="submit-button" or data-ocr-upload-target="submitButton"
export default class extends Controller {
  static targets = ['nameInput', 'fileInput', 'submitButton'];

  connect() {
    // Fallback: if submitButton target is not used, use #submit-button by id
    this.submitEl = this.hasSubmitButtonTarget ? this.submitButtonTarget : document.getElementById('submit-button');
    this.nameEl = this.hasNameInputTarget ? this.nameInputTarget : null;
    this.fileEl = this.hasFileInputTarget ? this.fileInputTarget : null;

    // Bind listeners
    if (this.nameEl) this.nameEl.addEventListener('input', this.updateState);
    if (this.fileEl) this.fileEl.addEventListener('change', this.updateState);

    // Initial state
    this.updateState();
  }

  disconnect() {
    if (this.nameEl) this.nameEl.removeEventListener('input', this.updateState);
    if (this.fileEl) this.fileEl.removeEventListener('change', this.updateState);
  }

  updateState = () => {
    const nameOk = !!(this.nameEl && this.nameEl.value && this.nameEl.value.trim().length > 0);
    const fileOk = !!(this.fileEl && this.fileEl.files && this.fileEl.files.length > 0 && this.isPdf(this.fileEl.files[0]));
    const enabled = nameOk && fileOk;
    if (this.submitEl) this.submitEl.disabled = !enabled;
  }

  isPdf(file) {
    // Accept common PDF mime types and extension safety check
    if (!file) return false;
    const type = (file.type || '').toLowerCase();
    if (type === 'application/pdf') return true;
    const name = (file.name || '').toLowerCase();
    return name.endsWith('.pdf');
  }
}
