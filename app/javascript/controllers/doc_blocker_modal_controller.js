import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modalTitle",
    "stepBadge", "filename",
    "missionId", "stepId", "documentId", "titleInput", "submitBtn",
    "createSection", "readSection",
    "existingTitle", "existingStatus", "existingTime"
  ]

  // Triggered by Bootstrap's show.bs.modal (old data-bs-toggle buttons)
  populate(event) {
    const btn = event.relatedTarget
    if (!btn) return
    this.#populateShared({
      mode:          btn.dataset.mode          || "create",
      stepName:      btn.dataset.stepName      || "Sans étape",
      stepIcon:      btn.dataset.stepIcon      || "",
      docName:       btn.dataset.docName       || "",
      missionId:     btn.dataset.missionId     || "",
      stepId:        btn.dataset.stepId        || "",
      docId:         btn.dataset.docId         || "",
      blockerId:     btn.dataset.blockerId     || "",
      blockerTitle:  btn.dataset.blockerTitle  || "",
      blockerStatus: btn.dataset.blockerStatus || "",
      blockerTime:   btn.dataset.blockerTime   || ""
    })
  }

  // Triggered by blocker-modal controller via window custom event
  populateFromEvent(event) {
    this.#populateShared(event.detail)
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

  #populateShared(data) {
    const stepIcon = data.stepIcon || ""
    const stepName = data.stepName || "Sans étape"

    this.stepBadgeTarget.innerHTML = stepIcon
      ? `<i class="${stepIcon}"></i> ${stepName}`
      : stepName
    this.filenameTarget.textContent = data.docName || ""

    if ((data.mode || "create") === "read") {
      this.#showRead(data)
    } else {
      this.#showCreate(data)
    }
  }

  #showCreate(data) {
    this.modalTitleTarget.textContent = "Bloquer cette étape"
    this.createSectionTarget.classList.remove("d-none")
    this.readSectionTarget.classList.add("d-none")

    this.missionIdTarget.value  = data.missionId || ""
    this.stepIdTarget.value     = data.stepId    || ""
    this.documentIdTarget.value = data.docId     || ""
    this.titleInputTarget.value = ""

    this.element.addEventListener("shown.bs.modal", () => this.titleInputTarget.focus(), { once: true })
  }

  #showRead(data) {
    this.modalTitleTarget.textContent = "Point bloquant"
    this.createSectionTarget.classList.add("d-none")
    this.readSectionTarget.classList.remove("d-none")

    this.existingTitleTarget.textContent  = data.blockerTitle  || ""
    this.existingStatusTarget.textContent = data.blockerStatus || "En attente"
    this.existingTimeTarget.textContent   = data.blockerTime   || ""

    this._blockerId = data.blockerId || ""
    this._docId     = data.docId     || ""
  }
}
