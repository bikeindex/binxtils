# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"
require "active_record"

# Stub Rails.application for TimeParser.default_time_zone
# The code calls: Rails.application.class.config.time_zone
module Rails
  Config = Struct.new(:time_zone)

  class Application
    def self.config
      @config ||= Config.new("Central Time (US & Canada)")
    end
  end

  def self.application
    @application ||= Application.new
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
