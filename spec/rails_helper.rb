# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require "rspec/rails"
require "capybara/rspec"
require_relative "spec_helper"

# Ensure the test database exists, then load schema fresh each run.
begin
  ActiveRecord::Base.connection.execute("SELECT 1")
rescue ActiveRecord::NoDatabaseError
  ActiveRecord::Tasks::DatabaseTasks.create_current
end
ActiveRecord::Schema.verbose = false
load Rails.root.join("db/schema.rb")

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.before(:each, type: :system) do
    driven_by :rack_test
  end
end
