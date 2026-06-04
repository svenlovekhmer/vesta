import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  show({ currentTarget }) {
    const tab = currentTarget.dataset.tab
    this.tabTargets.forEach(t =>
      t.classList.toggle("mission-tabs__btn--active", t.dataset.tab === tab)
    )
    this.panelTargets.forEach(p =>
      p.classList.toggle("d-none", p.dataset.panel !== tab)
    )
  }
}
