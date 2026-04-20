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
require "binxtils/set_period"
require "binxtils/sortable_table"
require "binxtils/sortable_helper"
require "binxtils/controller_namespace"
require "binxtils/nav_helper"
require_relative "binxtils/engine" if defined?(Rails::Engine)
