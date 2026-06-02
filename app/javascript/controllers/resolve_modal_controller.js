import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "comment", "preview", "previewContainer", "submit"]
  static values = { originalTitle: String }

  connect() {
    this.updatePreview()
  }

  get computedTitle() {
    const radio = this.radioTargets.find(r => r.checked)
    const type = radio ? radio.value : null
    const comment = this.hasCommentTarget ? this.commentTarget.value.trim() : ""

    if (type === "decided") return comment || this.originalTitleValue
    if (type === "received") return this.originalTitleValue + " (reçu)"
    if (type === "unnecessary") return "Annulé – " + this.originalTitleValue
    return this.originalTitleValue
  }

  updatePreview() {
    const radio = this.radioTargets.find(r => r.checked)

    if (!radio) {
      this.previewTarget.innerHTML = "<em class=\"text-muted\">Sélectionnez un motif…</em>"
      this.previewContainerTarget.classList.remove("resolve-preview--ready")
      return
    }

    this.previewTarget.textContent = this.computedTitle
    this.previewContainerTarget.classList.add("resolve-preview--ready")
  }

  submit(event) {
    const selectedRadio = this.radioTargets.find(r => r.checked)
    if (!selectedRadio) {
      event.preventDefault()
      this.radioTargets[0]?.reportValidity()
    }
  }
}
