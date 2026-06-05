import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "input"]
  static values = { url: String, param: String, model: String }

  connect() {
    this.#pencil = document.createElement("i")
    this.#pencil.className = "fa-solid fa-pen-to-square inline-edit__pencil"
    this.textTarget.insertAdjacentElement("beforeend", this.#pencil)
  }

  disconnect() {
    this.#pencil?.remove()
  }

  edit() {
    this.#originalValue = this.textTarget.textContent.trim()
    this.inputTarget.value = this.#originalValue
    this.textTarget.classList.add("d-none")
    this.#pencil.classList.add("d-none")
    this.inputTarget.classList.remove("d-none")
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  async save() {
    if (this.#saving) return
    this.#saving = true

    const value = this.inputTarget.value.trim()

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
          "Accept": "application/json"
        },
        body: JSON.stringify({ [this.modelValue]: { [this.paramValue]: value } })
      })

      if (response.ok) {
        this.textTarget.textContent = value
      } else {
        this.inputTarget.value = this.#originalValue
      }
    } catch {
      this.inputTarget.value = this.#originalValue
    } finally {
      this.#saving = false
      this.inputTarget.classList.add("d-none")
      this.#pencil.classList.remove("d-none")
      this.textTarget.classList.remove("d-none")
    }
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.#saving = true  // prevent blur from firing a save
      this.inputTarget.value = this.#originalValue
      this.inputTarget.classList.add("d-none")
      this.#pencil.classList.remove("d-none")
      this.textTarget.classList.remove("d-none")
      this.#saving = false
    } else if (event.key === "Enter" && this.inputTarget.tagName !== "TEXTAREA") {
      event.preventDefault()
      this.inputTarget.blur()
    }
  }

  #saving = false
  #originalValue = ""
  #pencil = null
}
