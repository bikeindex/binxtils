# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SortableHelper rendering", type: :system do
  before { Cryptid.seed_samples! }

  context "active sort column" do
    it "marks the current column's link with .active and an arrow indicator" do
      visit cryptids_path(sort: "name", direction: "asc")

      active_link = find("a.sortable-link.active")
      expect(active_link.text).to include("Name")
      # Arrow shows the current sort direction (asc → ↑).
      expect(active_link).to have_css("span.sortable-direction", text: "↑")
    end
  end

  context "inactive sort column" do
    it "renders a sortable-link without the .active class" do
      visit cryptids_path(sort: "name", direction: "asc")

      sightings_link = find("a.sortable-link", text: "Sightings")
      expect(sightings_link[:class]).not_to include("active")
    end
  end

  context "clicking an inactive column" do
    it "links to that column with the default desc direction" do
      visit cryptids_path(sort: "name", direction: "asc")
      click_link "Sightings"

      expect(page).to have_current_path(/sort=sightings/)
      expect(page).to have_current_path(/direction=desc/)
    end
  end
end
