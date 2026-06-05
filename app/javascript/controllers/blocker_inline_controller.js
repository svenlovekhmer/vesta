import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "form", "toggleBtn", "stepIdInput", "fileNotice", "fileNoticeName", "titleInput"]
  static values = { missionId: Number }

  // Called when step-selector dispatches step-selector:selected
  onStepSelected(event) {
    const { stepId, stepName } = event.detail
    if (stepId) {
      this.panelTarget.classList.remove("d-none")
      if (this.hasStepIdInputTarget) this.stepIdInputTarget.value = stepId
    } else {
      this.panelTarget.classList.add("d-none")
      this.#hideForm()
    }
  }

  // Called when document-upload dispatches document-upload:filesChanged
  onFilesChanged(event) {
    const { fileNames } = event.detail
    if (fileNames && fileNames.length > 0) {
      this.fileNoticeTarget.classList.remove("d-none")
      this.fileNoticeNameTarget.textContent = fileNames[0]
    } else {
      this.fileNoticeTarget.classList.add("d-none")
    }
  }

  toggle() {
    if (this.formTarget.classList.contains("d-none")) {
      this.formTarget.classList.remove("d-none")
      this.toggleBtnTarget.classList.add("d-none")
      if (this.hasTitleInputTarget) this.titleInputTarget.focus()
    } else {
      this.#hideForm()
    }
  }

  cancel() {
    this.#hideForm()
  }

  #hideForm() {
    this.formTarget.classList.add("d-none")
    if (this.hasToggleBtnTarget) this.toggleBtnTarget.classList.remove("d-none")
  }
}
