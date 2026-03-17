# frozen_string_literal: true

require "spec_helper"
require "open3"

RSpec.describe "binxtils:char_count" do
  def run_char_count(*args)
    Open3.capture2("bin/rake", "binxtils:char_count", *args)
  end

  context "with default paths" do
    it "outputs a positive integer" do
      stdout, status = run_char_count
      expect(status).to be_success
      expect(stdout.strip.to_i).to be > 0
    end
  end

  context "with a specific path" do
    it "outputs a count for that path" do
      stdout, status = run_char_count("lib")
      expect(status).to be_success
      expect(stdout.strip.to_i).to be > 0
    end
  end

  context "with a single file" do
    it "counts non-whitespace characters excluding comments" do
      stdout, status = run_char_count("lib/binxtils/version.rb")
      expect(status).to be_success
      expect(stdout.strip.to_i).to be_between(31, 35)
    end
  end

  context "with a path containing no matching files" do
    it "outputs zero" do
      stdout, status = run_char_count("tmp")
      expect(status).to be_success
      expect(stdout.strip.to_i).to eq 0
    end
  end
end
