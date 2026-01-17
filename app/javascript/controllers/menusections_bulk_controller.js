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
    "modal",
    "modalTitle",
    "modalBodyArchive",
    "modalBodyStatus",
    "modalStatusSelect",
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

    if (this.hasModalBodyArchiveTarget) this.modalBodyArchiveTarget.classList.add("d-none");
    if (this.hasModalBodyStatusTarget) this.modalBodyStatusTarget.classList.add("d-none");

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
    }

    if (this.bsModal) this.bsModal.hide();

    const form = this.element.closest("form");
    if (form) form.requestSubmit();
  }
}
