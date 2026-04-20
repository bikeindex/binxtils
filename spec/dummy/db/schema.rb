# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table :users, force: :cascade do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.timestamps
  end

  create_table :cryptids, force: :cascade do |t|
    t.string :name, null: false
    t.string :region
    t.string :credibility
    t.string :enthusiasm
    t.integer :sightings, default: 0, null: false
    t.datetime :first_seen
    t.timestamps
  end
end
