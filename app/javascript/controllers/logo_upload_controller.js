import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "removeField", "removeBtn"]

  trigger() {
    this.inputTarget.click()
  }

  change() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.classList.remove("d-none")
      this.placeholderTarget.classList.add("d-none")
      this.removeBtnTarget.classList.remove("d-none")
      this.removeFieldTarget.value = "0"
    }
    reader.readAsDataURL(file)
  }

  remove(event) {
    event.stopPropagation()
    this.inputTarget.value = ""
    this.previewTarget.src = ""
    this.previewTarget.classList.add("d-none")
    this.placeholderTarget.classList.remove("d-none")
    this.removeBtnTarget.classList.add("d-none")
    this.removeFieldTarget.value = "1"
  }
}
