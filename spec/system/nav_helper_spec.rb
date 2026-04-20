# frozen_string_literal: true

require "rails_helper"

RSpec.describe "NavHelper#current_page_active?", type: :system do
  context "on the cryptids index" do
    it "marks the Cryptids nav link active and leaves Users inactive" do
      visit cryptids_path

      expect(find("#nav-cryptids")[:class]).to include("active")
      expect(find("#nav-users")[:class].to_s).not_to include("active")
    end
  end

  context "on the users index" do
    it "marks the Users nav link active and leaves Cryptids inactive" do
      visit users_path

      expect(find("#nav-users")[:class]).to include("active")
      expect(find("#nav-cryptids")[:class].to_s).not_to include("active")
    end
  end
end
