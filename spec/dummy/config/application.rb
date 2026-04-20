# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

require "binxtils"

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.0
    config.eager_load = false
    config.time_zone = "Central Time (US & Canada)"
    config.session_store :cookie_store, key: "_binxtils_dummy_session"
    config.secret_key_base = "binxtils_dummy_test_secret_key_base_padded_to_minimum_length"
    config.hosts.clear
  end
end
