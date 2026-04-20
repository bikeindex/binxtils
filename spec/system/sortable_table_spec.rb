# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sortable cryptids table", type: :system do
  before { Cryptid.seed_samples! }

  context "default landing" do
    it "uses the controller-defined default sort (sightings desc)" do
      visit cryptids_path

      names = all("tr[data-cryptid-name]").map { |row| row["data-cryptid-name"] }
      expect(names).to eq(%w[Bigfoot Loch\ Ness\ Monster Mothman Chupacabra Jersey\ Devil Okapi])
    end
  end

  context "clicking a sortable header" do
    it "re-orders by the chosen column" do
      visit cryptids_path
      click_link "Name"

      expect(page).to have_current_path(/sort=name/)
      names = all("tr[data-cryptid-name]").map { |row| row["data-cryptid-name"] }
      expect(names).to eq(names.sort.reverse)
    end
  end

  context "explicit ascending direction" do
    it "honors sort and direction params" do
      visit cryptids_path(sort: "sightings", direction: "asc")

      sightings = all("td.cryptid-sightings").map { |td| td.text.to_i }
      expect(sightings).to eq(sightings.sort)
    end
  end
end
