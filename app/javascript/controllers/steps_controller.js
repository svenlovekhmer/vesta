import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["list", "row", "rowTemplate", "badge", "handle"]
  static values  = { templates: Array }

  connect() {
    this._sortable = Sortable.create(this.listTarget, {
      handle: "[data-steps-target='handle']",
      animation: 150,
      onEnd: () => this._updateNumbers()
    })
    this._updateNumbers()
  }

  disconnect() {
    this._sortable?.destroy()
  }

  addStep() {
    const idx = Date.now()
    const wrapper = document.createElement("div")
    wrapper.appendChild(this.rowTemplateTarget.content.cloneNode(true))
    wrapper.innerHTML = wrapper.innerHTML.replaceAll("NEW_INDEX", idx)
    this.listTarget.appendChild(wrapper.firstElementChild)
    this._updateNumbers()
  }

  removeStep(event) {
    const row = event.currentTarget.closest("[data-steps-target='row']")
    const destroyField = row.querySelector("[name*='[_destroy]']")
    if (destroyField && row.querySelector("[name*='[id]']")) {
      destroyField.value = "1"
      row.classList.add("d-none")
    } else {
      row.remove()
    }
    this._updateNumbers()
  }

  loadTemplate(event) {
    const id = parseInt(event.currentTarget.dataset.templateId, 10)
    const tpl = this.templatesValue.find(t => t.id === id)
    if (!tpl) return

    this._visibleRows().forEach(row => row.remove())

    tpl.items.forEach((item, i) => {
      const idx = Date.now() + i
      const wrapper = document.createElement("div")
      wrapper.appendChild(this.rowTemplateTarget.content.cloneNode(true))
      wrapper.innerHTML = wrapper.innerHTML.replaceAll("NEW_INDEX", idx)
      const newRow = wrapper.firstElementChild
      newRow.querySelector(".step-title-input").value = item.title
      this.listTarget.appendChild(newRow)
    })

    this._updateNumbers()
  }

  _visibleRows() {
    return this.rowTargets.filter(r => !r.classList.contains("d-none"))
  }

  _updateNumbers() {
    this._visibleRows().forEach((row, i) => {
      const badge = row.querySelector("[data-steps-target='badge']")
      if (badge) badge.textContent = i + 1
      const pos = row.querySelector("[name*='[position]']")
      if (pos) pos.value = i + 1
    })
  }
}
