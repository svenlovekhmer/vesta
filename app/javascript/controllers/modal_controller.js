import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame"]

  connect() {
    this.bsModal = new window.bootstrap.Modal(this.element)

    this._onFrameRender = this.show.bind(this)
    this._onModalHidden = this.clearFrame.bind(this)

    this.frameTarget.addEventListener("turbo:frame-render", this._onFrameRender)
    this.element.addEventListener("hidden.bs.modal", this._onModalHidden)

    this.observer = new MutationObserver(() => {
      if (this.frameTarget.children.length === 0) this.bsModal.hide()
    })
    this.observer.observe(this.frameTarget, { childList: true })
  }

  disconnect() {
    this.frameTarget.removeEventListener("turbo:frame-render", this._onFrameRender)
    this.element.removeEventListener("hidden.bs.modal", this._onModalHidden)
    this.observer.disconnect()
    this.bsModal.dispose()
  }

  show() {
    this.bsModal.show()
  }

  clearFrame() {
    this.frameTarget.innerHTML = ""
  }
}
