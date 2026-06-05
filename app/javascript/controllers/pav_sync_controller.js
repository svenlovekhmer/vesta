import { Controller } from "@hotwired/stimulus"

const DAY = 24 * 60 * 60 * 1000

const WORDS = [
  "Lecture", "Analyse", "Extraction", "Compréhension",
  "Échanges", "Décisions", "Matériaux", "Architecture",
  "Synthèse", "Traitement", "Contexte", "Planification",
]

const STATE_CONFIGS = {
  never:    { icon: "ti-clock",         color: "text-secondary", style: null,      label: "jamais synchronisé" },
  neutral:  { icon: "ti-clock",         color: "text-secondary", style: null,      label: null },
  warning:  { icon: "ti-clock",         color: null,             style: "#BA7517", label: null },
  critical: { icon: "ti-alert-circle",  color: null,             style: "#BA7517", label: null },
  loading:  { icon: "ti-loader pav-sync-label__spin", color: null, style: "#185FA5", label: "synchronisation..." },
  fresh:    { icon: "ti-circle-check",  color: null,             style: "#0F6E56", label: "à l'instant" },
  error:    { icon: "ti-alert-circle",  color: "text-danger",    style: null,      label: "erreur synchro" },
}

export default class extends Controller {
  static targets = ["syncBtn", "syncLoader", "syncWord", "syncLabel"]

  connect() {
    this.updateLabels()
    this._interval = setInterval(() => this.updateLabels(), 60_000)
  }

  disconnect() {
    clearInterval(this._interval)
    clearInterval(this._wordInterval)
  }

  syncAll() {
    this._showLoader()
  }

  syncLabelTargetConnected() {
    if (!this._anyLoading()) this._showBtn()
  }

  updateLabels() {
    this.syncLabelTargets.forEach(el => {
      if (el.dataset.state === "loading") return
      this._setState(el, this._computeState(el.dataset.syncedAt))
    })
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  _computeState(syncedAt) {
    if (!syncedAt) return "never"
    const age = Date.now() - new Date(syncedAt).getTime()
    if (age < 2 * DAY) return "neutral"
    if (age < 5 * DAY) return "warning"
    return "critical"
  }

  _setState(el, state) {
    const cfg = STATE_CONFIGS[state] || STATE_CONFIGS.never
    const label = cfg.label ?? `synchro ${this._rel(el.dataset.syncedAt)}`

    el.dataset.state = state
    el.className = ["pav-sync-label", cfg.color].filter(Boolean).join(" ")
    el.style.color = cfg.style || ""
    el.innerHTML = `<i class="ti ${cfg.icon}"></i> ${label}`
  }

  _rel(isoDate) {
    const mins = Math.round((Date.now() - new Date(isoDate).getTime()) / 60_000)
    if (mins < 60) return `il y a ${mins}min`
    const hrs = Math.round(mins / 60)
    if (hrs < 24)  return `il y a ${hrs}h`
    return `il y a ${Math.round(hrs / 24)}j`
  }

  _anyLoading() {
    return this.syncLabelTargets.some(el => el.dataset.state === "loading")
  }

  _showLoader() {
    if (this.hasSyncBtnTarget)    this.syncBtnTarget.classList.add("d-none")
    if (this.hasSyncLoaderTarget) this.syncLoaderTarget.classList.remove("d-none")
    this._startWordCycling()
  }

  _showBtn() {
    clearInterval(this._wordInterval)
    if (this.hasSyncBtnTarget)    this.syncBtnTarget.classList.remove("d-none")
    if (this.hasSyncLoaderTarget) this.syncLoaderTarget.classList.add("d-none")
  }

  _startWordCycling() {
    if (!this.hasSyncWordTarget) return
    this._showWord(this._pick())
    this._wordInterval = setInterval(() => this._showWord(this._pick()), 700)
  }

  _pick() {
    return WORDS[Math.floor(Math.random() * WORDS.length)]
  }

  _showWord(word) {
    const el = this.syncWordTarget
    el.classList.remove("gmail-sync__word--in")
    void el.offsetWidth
    el.textContent = word
    el.classList.add("gmail-sync__word--in")
  }
}
