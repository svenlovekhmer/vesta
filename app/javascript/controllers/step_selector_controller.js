import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "triggerDot", "triggerLabel"]

  connect() {
    this._onClickOutside = this.#clickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this._onClickOutside)
  }

  toggle(event) {
    event.stopPropagation()
    if (this.menuTarget.classList.contains("step-selector__menu--open")) {
      this.#close()
    } else {
      this.menuTarget.classList.add("step-selector__menu--open")
      document.addEventListener("click", this._onClickOutside)
    }
  }

  select(event) {
    const { stepId, stepName } = event.currentTarget.dataset
    this.triggerLabelTarget.textContent = stepName || "— Sans étape —"
    if (stepId) {
      this.triggerDotTarget.classList.add("step-selector__dot--active")
    } else {
      this.triggerDotTarget.classList.remove("step-selector__dot--active")
    }
    this.dispatch("selected", { detail: { stepId: stepId || "", stepName: stepName || "" } })
    this.#close()
  }

  #close() {
    this.menuTarget.classList.remove("step-selector__menu--open")
    document.removeEventListener("click", this._onClickOutside)
  }

  #clickOutside(event) {
    if (!this.element.contains(event.target)) this.#close()
  }
}
