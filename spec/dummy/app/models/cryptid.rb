# frozen_string_literal: true

class Cryptid < ApplicationRecord
  def self.samples
    [
      {name: "Mothman", region: "West Virginia", credibility: "Medium", enthusiasm: "Extreme", sightings: 142, first_seen: Time.zone.parse("1966-11-15")},
      {name: "Bigfoot", region: "Pacific Northwest", credibility: "Low", enthusiasm: "Extreme", sightings: 10000, first_seen: Time.zone.parse("1958-08-27")},
      {name: "Loch Ness Monster", region: "Scottish Highlands", credibility: "Low", enthusiasm: "High", sightings: 1036, first_seen: Time.zone.parse("1933-05-02")},
      {name: "Chupacabra", region: "Puerto Rico", credibility: "Low", enthusiasm: "Medium", sightings: 87, first_seen: Time.zone.parse("1995-03-01")},
      {name: "Jersey Devil", region: "Pine Barrens, NJ", credibility: "Low", enthusiasm: "Low", sightings: 53, first_seen: Time.zone.parse("1909-01-16")},
      {name: "Okapi", region: "Congo", credibility: "Confirmed", enthusiasm: "None", sightings: 1, first_seen: Time.zone.parse("1901-06-01")}
    ]
  end

  def self.seed_samples!
    samples.each { |attrs| create!(attrs) }
  end
end
