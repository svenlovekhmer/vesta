import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "row", "badge", "rowTemplate"]

  connect() {
    this._updateNumbers()
  }

  addItem() {
    const idx = Date.now()
    const wrapper = document.createElement("div")
    wrapper.appendChild(this.rowTemplateTarget.content.cloneNode(true))
    wrapper.innerHTML = wrapper.innerHTML.replaceAll("NEW_INDEX", idx)
    this.listTarget.appendChild(wrapper.firstElementChild)
    this._updateNumbers()
  }

  removeItem(event) {
    const row = event.currentTarget.closest("[data-template-items-target='row']")
    const destroyField = row.querySelector("[name*='[_destroy]']")
    if (destroyField && row.querySelector("[name*='[id]']")) {
      destroyField.value = "1"
      row.classList.add("d-none")
    } else {
      row.remove()
    }
    this._updateNumbers()
  }

  _visibleRows() {
    return this.rowTargets.filter(r => !r.classList.contains("d-none"))
  }

  _updateNumbers() {
    this._visibleRows().forEach((row, i) => {
      const badge = row.querySelector("[data-template-items-target='badge']")
      if (badge) badge.textContent = i + 1
      const pos = row.querySelector("[name*='[position]']")
      if (pos) pos.value = i + 1
    })
  }
}
