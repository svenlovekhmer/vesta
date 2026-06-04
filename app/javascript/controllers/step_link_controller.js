import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { missionId: Number }

  dragstart(event) {
    const id = event.currentTarget.dataset.decisionLogId
    event.dataTransfer.setData("text/plain", id)
    event.dataTransfer.effectAllowed = "move"
    event.currentTarget.classList.add("log-item--dragging")
    this.element.querySelectorAll(".step-link-drop-zone").forEach(z =>
      z.classList.add("step-link-drop-zone--active")
    )
  }

  dragend(event) {
    event.currentTarget.classList.remove("log-item--dragging")
    this.element.querySelectorAll(".step-link-drop-zone").forEach(z =>
      z.classList.remove("step-link-drop-zone--active", "step-link-drop-zone--over")
    )
  }

  dragover(event) {
    event.preventDefault()
    event.currentTarget.classList.add("step-link-drop-zone--over")
  }

  dragleave(event) {
    event.currentTarget.classList.remove("step-link-drop-zone--over")
  }

  async drop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove("step-link-drop-zone--over")

    const decisionLogId = event.dataTransfer.getData("text/plain")
    const stepId = event.currentTarget.dataset.stepId

    const response = await fetch("/mission_step_blockers", {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        decision_log_id: decisionLogId,
        step_id: stepId,
        mission_id: this.missionIdValue
      })
    })

    if (response.ok) Turbo.renderStreamMessage(await response.text())
  }

  async unlink(event) {
    event.stopPropagation()
    const blockerId = event.currentTarget.dataset.blockerId

    const response = await fetch(`/mission_step_blockers/${blockerId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })

    if (response.ok) Turbo.renderStreamMessage(await response.text())
  }

  highlight(event) {
    const logId = event.currentTarget.dataset.decisionLogId
    const card = this.element.querySelector(`#decision_log_${logId}`)
    if (!card) return

    card.classList.add("log-item--highlighted")
    card.scrollIntoView({ behavior: "smooth", block: "nearest" })
    setTimeout(() => card.classList.remove("log-item--highlighted"), 2000)
  }
}
