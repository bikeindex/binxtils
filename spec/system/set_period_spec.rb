# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SetPeriod time filtering", type: :system do
  before { Cryptid.seed_samples! }

  context "default period (all)" do
    it "shows every cryptid regardless of first_seen date" do
      visit cryptids_path

      expect(all("tr[data-cryptid-name]").count).to eq(Cryptid.count)
    end
  end

  context "period=year" do
    it "filters out cryptids first seen more than a year ago" do
      visit cryptids_path(period: "year")

      expect(all("tr[data-cryptid-name]")).to be_empty
    end
  end

  context "custom period with start_time and end_time" do
    it "filters cryptids to the supplied window" do
      visit cryptids_path(period: "custom", start_time: "1960-01-01", end_time: "1970-01-01")

      names = all("tr[data-cryptid-name]").map { |row| row["data-cryptid-name"] }
      expect(names).to eq(["Mothman"])
    end
  end
end
