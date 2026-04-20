# frozen_string_literal: true

require "functionable"
require "active_support"
require "active_support/core_ext"
require "active_record"
require "loofah"
require "rails-html-sanitizer"

require_relative "binxtils/input_normalizer"
require_relative "binxtils/time_zone_parser"
require_relative "binxtils/time_parser"
require_relative "binxtils/set_period"
require_relative "binxtils/sortable_table"
require_relative "binxtils/sortable_helper"
require "binxtils/controller_namespace"
require_relative "binxtils/nav_helper"
require_relative "binxtils/railtie" if defined?(Rails::Railtie)
