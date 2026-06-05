import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { href: String }

  navigate(event) {
    if (event.target.closest("[data-row-link-exempt]")) return
    window.location.href = this.hrefValue
  }
}
