# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"
require "active_record"

# Stub Rails.application for TimeParser.default_time_zone when the full
# Rails framework isn't loaded (i.e. unit specs that don't go through
# rails_helper). The code calls: Rails.application.class.config.time_zone.
# Avoid defining a Rails::Application class — that would collide with the
# real one if a system spec later loads Rails in the same process.
unless defined?(Rails)
  module Rails
    stub_config = Struct.new(:time_zone).new("Central Time (US & Canada)")
    stub_app_class = Class.new
    stub_app_class.define_singleton_method(:config) { stub_config }
    stub_app = stub_app_class.new
    define_singleton_method(:application) { stub_app }
  end
end

require "binxtils"

DEFAULT_TIME_ZONE = Binxtils::TimeParser.default_time_zone
Time.zone = DEFAULT_TIME_ZONE

# In Rails, Time.zone falls back to the app's configured default when set to nil.
# Replicate that behavior for tests.
module DefaultTimeZoneFallback
  def zone
    super || DEFAULT_TIME_ZONE
  end
end
Time.singleton_class.prepend(DefaultTimeZoneFallback)

RSpec::Matchers.define :match_time do |expected|
  match do |actual|
    actual.to_i == expected.to_i
  end

  failure_message do |actual|
    "expected #{actual} (#{actual.to_i}) to match time #{expected} (#{expected.to_i})"
  end
end
