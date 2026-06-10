class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def after_sign_in_path_for(_resource)
    dashboard_path
  end

  helper_method :breadcrumbs

  def add_breadcrumb(name, path = nil)
    breadcrumbs << { name: name, path: path }
  end

  def breadcrumbs
    @breadcrumbs ||= []
  end

  def default_url_options
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end
end
