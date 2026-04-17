# frozen_string_literal: true

module Binxtils
  module NavHelper
    def current_page_active?(link_path, match_controller = false)
      return current_page?(link_path) unless match_controller

      link_controller = Rails.application.routes.recognize_path(link_path)[:controller]
      Rails.application.routes.recognize_path(request.url)[:controller] == link_controller
    rescue ActionController::RoutingError
      false
    end
  end
end
