# frozen_string_literal: true

require_relative "lib/binxtils/version"

Gem::Specification.new do |spec|
  spec.name = "binxtils"
  spec.authors = ["Bike Index"]
  spec.summary = "Bike Index utility modules"
  spec.homepage = "https://github.com/bikeindex/binxtils"
  spec.license = "MIT"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/bikeindex/binxtils/issues",
    "homepage_uri" => "https://github.com/bikeindex/binxtils",
    "funding_uri" => "https://github.com/sponsors/bikeindex",
    "rubygems_mfa_required" => "true"
  }

  spec.version = Binxtils::VERSION

  spec.required_ruby_version = ">= 3.4"

  spec.files = Dir["lib/**/*"]
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]

  spec.add_dependency "functionable"
  spec.add_dependency "activesupport"
  spec.add_dependency "activerecord"
  spec.add_dependency "loofah"
  spec.add_dependency "rails-html-sanitizer"
end
