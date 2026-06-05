import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "dropZone", "preview", "fileList", "submitBtn", "stepInput"]

  #files = new DataTransfer()

  // ── Drop zone interactions ────────────────────────────────────────────

  dragover(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.add("drop-zone--over")
  }

  dragleave(event) {
    if (this.dropZoneTarget.contains(event.relatedTarget)) return
    this.dropZoneTarget.classList.remove("drop-zone--over")
  }

  drop(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.remove("drop-zone--over")
    this.#addFiles(event.dataTransfer.files)
  }

  openPicker(event) {
    if (event.target === this.fileInputTarget) return
    this.fileInputTarget.click()
  }

  pick() {
    this.#addFiles(this.fileInputTarget.files)
    this.fileInputTarget.value = ""
  }

  // ── File list management ──────────────────────────────────────────────

  remove(event) {
    const idx = parseInt(event.currentTarget.dataset.index)
    const updated = new DataTransfer()
    Array.from(this.#files.files).forEach((f, i) => { if (i !== idx) updated.items.add(f) })
    this.#files = updated
    this.#sync()
  }

  // ── Step selection (listens to step-selector:selected bubbling up) ────

  onStepSelected(event) {
    const { stepId } = event.detail
    this.stepInputTarget.value = stepId || ""
  }

  // ── Private ───────────────────────────────────────────────────────────

  #addFiles(fileList) {
    Array.from(fileList).forEach(f => this.#files.items.add(f))
    this.#sync()
  }

  #sync() {
    this.fileInputTarget.files = this.#files.files
    const files = Array.from(this.#files.files)

    if (files.length === 0) {
      this.previewTarget.classList.add("d-none")
      this.dispatch("filesChanged", { detail: { fileNames: [] } })
      return
    }

    this.previewTarget.classList.remove("d-none")
    this.fileListTarget.innerHTML = files.map((f, i) => `
      <li class="drop-zone__file-item">
        <span class="drop-zone__file-icon">${this.#icon(f.type)}</span>
        <span class="drop-zone__file-name">${f.name}</span>
        <span class="drop-zone__file-size">${this.#size(f.size)}</span>
        <button type="button"
                class="drop-zone__file-remove"
                data-action="click->document-upload#remove"
                data-index="${i}"
                aria-label="Retirer">×</button>
      </li>
    `).join("")

    const n = files.length
    this.submitBtnTarget.value = `Ajouter ${n} fichier${n > 1 ? "s" : ""} →`
    this.dispatch("filesChanged", { detail: { fileNames: files.map(f => f.name) } })
  }

  #icon(contentType) {
    if (contentType.includes("pdf"))                                   return "📄"
    if (contentType.startsWith("image/"))                              return "🖼️"
    if (contentType.includes("word") || contentType.includes("doc"))   return "📝"
    if (contentType.includes("sheet") || contentType.includes("excel"))return "📊"
    return "📎"
  }

  #size(bytes) {
    if (bytes < 1024)       return `${bytes} o`
    if (bytes < 1048576)    return `${(bytes / 1024).toFixed(0)} Ko`
    return `${(bytes / 1048576).toFixed(1)} Mo`
  }
}
