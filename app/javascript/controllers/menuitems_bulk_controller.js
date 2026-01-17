import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = [
    "checkbox",
    "selectAll",
    "apply",
    "operation",
    "value",
    "actionSelect",
    "selectedCount",
    "modal",
    "modalTitle",
    "modalBodyArchive",
    "modalBodyStatus",
    "modalBodyItemtype",
    "modalBodyAlcoholic",
    "modalStatusSelect",
    "modalItemtypeSelect",
    "modalAlcoholicSelect",
    "modalApply",
  ];

  connect() {
    if (this.hasModalTarget) {
      this.bsModal = new Modal(this.modalTarget);
    }
    this.sync();
  }

  enabledCheckboxes() {
    return this.checkboxTargets.filter((cb) => !cb.disabled);
  }

  selectedCheckboxes() {
    return this.enabledCheckboxes().filter((cb) => cb.checked);
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked;
    this.enabledCheckboxes().forEach((cb) => {
      cb.checked = checked;
    });
    this.sync();
  }

  sync() {
    const enabled = this.enabledCheckboxes();
    const selected = this.selectedCheckboxes();

    if (this.hasSelectedCountTarget) {
      this.selectedCountTarget.textContent = String(selected.length);
    }

    if (this.hasSelectAllTarget) {
      const allChecked = enabled.length > 0 && enabled.every((cb) => cb.checked);
      const someChecked = enabled.some((cb) => cb.checked);
      this.selectAllTarget.checked = allChecked;
      this.selectAllTarget.indeterminate = someChecked && !allChecked;
    }

    const action = this.hasActionSelectTarget ? this.actionSelectTarget.value : "";
    const anySelected = selected.length > 0;

    if (this.hasActionSelectTarget) {
      if (!anySelected) {
        this.actionSelectTarget.value = "";
      }
      this.actionSelectTarget.disabled = !anySelected;
    }

    // Reset hidden fields until we're ready
    if (this.hasOperationTarget) this.operationTarget.value = "";
    if (this.hasValueTarget) this.valueTarget.value = "";

    if (this.hasApplyTarget) {
      this.applyTarget.disabled = !(anySelected && action);
    }
  }

  beforeSubmit(event) {
    const selected = this.selectedCheckboxes();
    if (selected.length === 0) {
      event.preventDefault();
      return;
    }

    const op = this.hasOperationTarget ? this.operationTarget.value : "";
    const val = this.hasValueTarget ? this.valueTarget.value : "";
    if (!op || !val) {
      event.preventDefault();
    }
  }

  apply(event) {
    const action = this.hasActionSelectTarget ? this.actionSelectTarget.value : "";
    event.preventDefault();

    if (!this.bsModal) return;

    // Configure modal
    if (this.hasModalBodyArchiveTarget) this.modalBodyArchiveTarget.classList.add("d-none");
    if (this.hasModalBodyStatusTarget) this.modalBodyStatusTarget.classList.add("d-none");
    if (this.hasModalBodyItemtypeTarget) this.modalBodyItemtypeTarget.classList.add("d-none");
    if (this.hasModalBodyAlcoholicTarget) this.modalBodyAlcoholicTarget.classList.add("d-none");

    if (this.hasModalApplyTarget) {
      this.modalApplyTarget.textContent = "Apply";
      this.modalApplyTarget.classList.remove("btn-danger");
      this.modalApplyTarget.classList.add("btn-primary");
    }

    if (action === "archive") {
      if (this.hasModalTitleTarget) this.modalTitleTarget.textContent = "Archive";
      if (this.hasModalBodyArchiveTarget) this.modalBodyArchiveTarget.classList.remove("d-none");
      if (this.hasModalApplyTarget) {
        this.modalApplyTarget.textContent = "Archive";
        this.modalApplyTarget.classList.remove("btn-primary");
        this.modalApplyTarget.classList.add("btn-danger");
      }
    } else if (action === "set_status") {
      if (this.hasModalTitleTarget) this.modalTitleTarget.textContent = "Set status";
      if (this.hasModalBodyStatusTarget) this.modalBodyStatusTarget.classList.remove("d-none");
    } else if (action === "set_itemtype") {
      if (this.hasModalTitleTarget) this.modalTitleTarget.textContent = "Set food type";
      if (this.hasModalBodyItemtypeTarget) this.modalBodyItemtypeTarget.classList.remove("d-none");
    } else if (action === "set_alcoholic") {
      if (this.hasModalTitleTarget) this.modalTitleTarget.textContent = "Set alcoholic";
      if (this.hasModalBodyAlcoholicTarget) this.modalBodyAlcoholicTarget.classList.remove("d-none");
    }

    this.bsModal.show();
  }

  confirmModalApply(event) {
    event.preventDefault();

    const action = this.hasActionSelectTarget ? this.actionSelectTarget.value : "";

    if (action === "archive") {
      if (this.hasOperationTarget) this.operationTarget.value = "archive";
      if (this.hasValueTarget) this.valueTarget.value = "1";
    } else if (action === "set_status") {
      const v = this.hasModalStatusSelectTarget ? this.modalStatusSelectTarget.value : "";
      if (this.hasOperationTarget) this.operationTarget.value = "set_status";
      if (this.hasValueTarget) this.valueTarget.value = v;
    } else if (action === "set_itemtype") {
      const v = this.hasModalItemtypeSelectTarget ? this.modalItemtypeSelectTarget.value : "";
      if (this.hasOperationTarget) this.operationTarget.value = "set_itemtype";
      if (this.hasValueTarget) this.valueTarget.value = v;
    } else if (action === "set_alcoholic") {
      const v = this.hasModalAlcoholicSelectTarget ? this.modalAlcoholicSelectTarget.value : "";
      if (this.hasOperationTarget) this.operationTarget.value = "set_alcoholic";
      if (this.hasValueTarget) this.valueTarget.value = v;
    }

    if (this.bsModal) this.bsModal.hide();

    // Submit the parent form
    const form = this.element.closest("form");
    if (form) form.requestSubmit();
  }
}
