import { Controller } from "@hotwired/stimulus"

const WORDS = [
  "Lecture", "Analyse", "Extraction", "Compréhension",
  "Échanges", "Décisions", "Matériaux", "Architecture",
  "Synthèse", "Traitement", "Contexte", "Planification",
  "Validation", "Points clés", "Résumé", "Identification",
  "Dossier", "Actions", "Révision", "Budget"
]

export default class extends Controller {
  static targets = ["btn", "loader", "word"]
  static values  = { aiCount: Number }

  handleClick(event) {
    event.preventDefault()

    if (this.aiCountValue > 0) {
      const msg = `${this.aiCountValue} analyse(s) IA existent déjà. Mettre à jour ?`
      if (!confirm(msg)) return
    }

    this.btnTarget.classList.add("d-none")
    this.loaderTarget.classList.remove("d-none")
    this._startCycling()

    this.element.querySelector("form").requestSubmit()
  }

  _startCycling() {
    this._showWord(this._pick())
    this._interval = setInterval(() => this._showWord(this._pick()), 700)
  }

  _pick() {
    return WORDS[Math.floor(Math.random() * WORDS.length)]
  }

  _showWord(word) {
    const el = this.wordTarget
    el.classList.remove("gmail-sync__word--in")
    void el.offsetWidth
    el.textContent = word
    el.classList.add("gmail-sync__word--in")
  }

  disconnect() {
    clearInterval(this._interval)
  }
}
