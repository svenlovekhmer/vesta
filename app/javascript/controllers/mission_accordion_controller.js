import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "detail", "chevron"]

  toggle(event) {
    const row     = event.currentTarget.closest("[data-mission-accordion-target='row']")
    const detail  = row.querySelector("[data-mission-accordion-target='detail']")
    const chevron = row.querySelector("[data-mission-accordion-target='chevron']")
    const isOpen  = detail.classList.contains("pav-row__detail--open")

    this.detailTargets.forEach(d => d.classList.remove("pav-row__detail--open"))
    this.chevronTargets.forEach(c => c.classList.remove("pav-chevron--open"))

    if (!isOpen) {
      detail.classList.add("pav-row__detail--open")
      chevron.classList.add("pav-chevron--open")
    }
  }
}
