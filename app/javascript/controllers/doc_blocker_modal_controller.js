import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modalTitle",
    "stepBadge", "filename",
    "missionId", "stepId", "documentId", "titleInput", "submitBtn",
    "createSection", "readSection",
    "existingTitle", "existingStatus", "existingTime"
  ]

  populate(event) {
    const btn = event.relatedTarget
    if (!btn) return

    const mode     = btn.dataset.mode     || "create"
    const stepName = btn.dataset.stepName || "Sans étape"
    const stepIcon = btn.dataset.stepIcon || ""
    const docName  = btn.dataset.docName  || ""

    // Step badge: icon (if present) + name
    this.stepBadgeTarget.innerHTML = stepIcon
      ? `<i class="${stepIcon}"></i> ${stepName}`
      : stepName
    this.filenameTarget.textContent = docName

    if (mode === "read") {
      this.#showRead(btn)
    } else {
      this.#showCreate(btn)
    }
  }

  onSubmitEnd(event) {
    if (event.detail.success) {
      bootstrap.Modal.getInstance(this.element)?.hide()
    }
  }

  async unblock() {
    const token = document.querySelector('[name="csrf-token"]').content
    const url   = `/mission_step_blockers/${this._blockerId}?document_id=${this._docId}`

    const response = await fetch(url, {
      method:  "DELETE",
      headers: { "X-CSRF-Token": token, "Accept": "text/vnd.turbo-stream.html" }
    })

    if (response.ok) {
      const html = await response.text()
      Turbo.renderStreamMessage(html)
      bootstrap.Modal.getInstance(this.element)?.hide()
    }
  }

  // ── Private ──────────────────────────────────────────────────────────────

  #showCreate(btn) {
    this.modalTitleTarget.textContent = "Bloquer cette étape"
    this.createSectionTarget.classList.remove("d-none")
    this.readSectionTarget.classList.add("d-none")

    this.missionIdTarget.value  = btn.dataset.missionId || ""
    this.stepIdTarget.value     = btn.dataset.stepId    || ""
    this.documentIdTarget.value = btn.dataset.docId     || ""
    this.titleInputTarget.value = ""

    this.element.addEventListener("shown.bs.modal", () => this.titleInputTarget.focus(), { once: true })
  }

  #showRead(btn) {
    this.modalTitleTarget.textContent = "Point bloquant"
    this.createSectionTarget.classList.add("d-none")
    this.readSectionTarget.classList.remove("d-none")

    this.existingTitleTarget.textContent  = btn.dataset.blockerTitle  || ""
    this.existingStatusTarget.textContent = btn.dataset.blockerStatus || "En attente"
    this.existingTimeTarget.textContent   = btn.dataset.blockerTime   || ""

    // Store for the unblock fetch
    this._blockerId = btn.dataset.blockerId || ""
    this._docId     = btn.dataset.docId     || ""
  }
}
