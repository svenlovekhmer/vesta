// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"

const hideFlashAlerts = () => {
  document.querySelectorAll(".alert").forEach((element) => {
    setTimeout(() => {
      const alert = window.bootstrap.Alert.getOrCreateInstance(element)
      alert.close()
    }, 5000)
  })
}

document.addEventListener("turbo:load", hideFlashAlerts)
document.addEventListener("turbo:render", hideFlashAlerts)
