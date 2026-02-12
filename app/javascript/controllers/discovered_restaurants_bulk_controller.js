import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "checkbox",
    "row",
    "selectAll",
    "apply",
    "operation",
    "value",
    "actionSelect",
    "menusFilter",
  ];

  connect() {
    if (this.hasMenusFilterTarget && String(this.menusFilterTarget.value || "").trim() === "") {
      this.menusFilterTarget.value = "1";
    }
    this.applyMenusFilter();
    this.sync();
  }

  applyMenusFilter() {
    if (!this.hasMenusFilterTarget || !this.hasRowTarget) return;

    const raw = this.menusFilterTarget.value;
    const min = Math.max(0, parseInt(raw, 10) || 0);

    this.rowTargets.forEach((row) => {
      const menus = parseInt(row.dataset.menusCount || "0", 10) || 0;
      const shouldShow = menus >= min;

      row.classList.toggle("d-none", !shouldShow);

      const cb = row.querySelector('input[type="checkbox"][data-discovered-restaurants-bulk-target="checkbox"]');
      if (cb) {
        cb.disabled = !shouldShow;
        if (!shouldShow) cb.checked = false;
      }
    });
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

  filterMenus() {
    this.applyMenusFilter();
    this.sync();
  }

  sync() {
    this.applyMenusFilter();

    const enabled = this.enabledCheckboxes();
    const selected = this.selectedCheckboxes();

    if (this.hasSelectAllTarget) {
      const allChecked = enabled.length > 0 && enabled.every((cb) => cb.checked);
      const someChecked = enabled.some((cb) => cb.checked);
      this.selectAllTarget.checked = allChecked;
      this.selectAllTarget.indeterminate = someChecked && !allChecked;
    }

    const anySelected = selected.length > 0;
    const action = this.hasActionSelectTarget ? this.actionSelectTarget.value : "";

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
    event.preventDefault();

    const action = this.hasActionSelectTarget ? this.actionSelectTarget.value : "";

    if (action === "approve") {
      if (this.hasOperationTarget) this.operationTarget.value = "set_status";
      if (this.hasValueTarget) this.valueTarget.value = "approved";
    } else if (action === "reject") {
      if (this.hasOperationTarget) this.operationTarget.value = "set_status";
      if (this.hasValueTarget) this.valueTarget.value = "rejected";
    } else if (action === "blacklist") {
      if (this.hasOperationTarget) this.operationTarget.value = "set_status";
      if (this.hasValueTarget) this.valueTarget.value = "blacklisted";
    } else if (action === "publish_preview") {
      if (this.hasOperationTarget) this.operationTarget.value = "publish_preview";
      if (this.hasValueTarget) this.valueTarget.value = "true";
    } else if (action === "unpublish_preview") {
      if (this.hasOperationTarget) this.operationTarget.value = "unpublish_preview";
      if (this.hasValueTarget) this.valueTarget.value = "true";
    }

    const form = this.element.querySelector("form") || this.element.closest("form");
    if (form) form.requestSubmit();
  }
}
