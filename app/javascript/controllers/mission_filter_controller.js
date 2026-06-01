import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "row"]

  filter(event) {
    const filter = event.currentTarget.dataset.filter

    this.tabTargets.forEach(tab => {
      tab.classList.toggle("active", tab === event.currentTarget)
    })

    this.rowTargets.forEach(row => {
      const show = filter === "all" || row.dataset.status === filter
      row.classList.toggle("d-none", !show)
    })
  }
}
