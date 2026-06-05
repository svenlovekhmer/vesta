import { Controller } from "@hotwired/stimulus"

// Card-level wrapper. Reads document data via Stimulus params and
// opens the shared #doc-blocker-modal via a custom event + Bootstrap API.
export default class extends Controller {
  open({ params }) {
    this.#dispatch({ mode: "create", ...params })
  }

  openReadMode({ params }) {
    this.#dispatch({ mode: "read", ...params })
  }

  #dispatch(detail) {
    window.dispatchEvent(new CustomEvent("blocker-modal:populate", { detail }))
    bootstrap.Modal.getOrCreateInstance(
      document.getElementById("doc-blocker-modal")
    ).show()
  }
}
