import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "card", "sortButton"]

  connect() {
    this.currentStatus = "all"
    this.sortDirection = "desc"

    this.apply()
  }

  filter() {
    this.apply()
  }

  setStatus(event) {
    this.currentStatus = event.currentTarget.dataset.status

    this.element.querySelectorAll(".interviews-filter-tab").forEach((tab) => {
      tab.classList.remove("active")
    })

    event.currentTarget.classList.add("active")

    this.apply()
  }

  toggleSort() {
    this.sortDirection =
      this.sortDirection === "desc" ? "asc" : "desc"

    this.sortButtonTarget.innerHTML =
      this.sortDirection === "desc"
        ? '<i class="fa-solid fa-arrow-down-short-wide"></i>'
        : '<i class="fa-solid fa-arrow-up-wide-short"></i>'

    this.applySort()
  }

  apply() {
    this.applyFilter()
    this.applySort()
  }

  applyFilter() {
    const query = this.searchTarget.value.toLowerCase().trim()

    this.cardTargets.forEach((card) => {
      const title = card.dataset.title || ""
      const email = card.dataset.email || ""
      const status = card.dataset.status || ""

      const matchesSearch =
        title.includes(query) || email.includes(query)

      const matchesStatus =
        this.currentStatus === "all" ||
        status === this.currentStatus ||
        (this.currentStatus === "ongoing" && status === "empty")

      card.hidden = !(matchesSearch && matchesStatus)
    })
  }

  applySort() {
    const list = this.element.querySelector(".clients-list")
    const sortedCards = [...this.cardTargets].sort((a, b) => {
      const diff =
        Number(b.dataset.createdAt) - Number(a.dataset.createdAt)

      return this.sortDirection === "desc" ? diff : -diff
    })
    console.log("after", sortedCards.map(card => card.dataset.createdAt))
    sortedCards.forEach((card) => list.appendChild(card))
  }
}
