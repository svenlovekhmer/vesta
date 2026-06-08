import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "row", "search", "sortButton"]

  connect() {
    this.activeFilter = "all"
    this.sortDirection = "desc"
  }

  filterByTab(event) {
    this.activeFilter = event.currentTarget.dataset.filter
    this.tabTargets.forEach(tab => tab.classList.toggle("active", tab === event.currentTarget))
    this.apply()
  }

  search() {
    this.apply()
  }

  toggleSort() {
    this.sortDirection = this.sortDirection === "desc" ? "asc" : "desc"
    this.sortButtonTarget.innerHTML = this.sortDirection === "desc"
      ? '<i class="fa-solid fa-arrow-down-short-wide"></i>'
      : '<i class="fa-solid fa-arrow-up-wide-short"></i>'
    this.apply()
  }

  apply() {
    const query = this.hasSearchTarget ? this.searchTarget.value.toLowerCase().trim() : ""

    this.rowTargets.forEach(row => {
      const matchesStatus = this.activeFilter === "all" || row.dataset.status === this.activeFilter
      const matchesSearch = !query || (row.dataset.title || "").includes(query)
      row.classList.toggle("d-none", !(matchesStatus && matchesSearch))
    })

    if (this.hasSortButtonTarget) this.applySort()
  }

  applySort() {
    const tbody = this.element.querySelector("tbody")
    if (!tbody) return
    const sorted = [...this.rowTargets].sort((a, b) => {
      const diff = Number(b.dataset.createdAt) - Number(a.dataset.createdAt)
      return this.sortDirection === "desc" ? diff : -diff
    })
    sorted.forEach(row => tbody.appendChild(row))
  }
}
