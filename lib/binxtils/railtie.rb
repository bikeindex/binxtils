# frozen_string_literal: true

module Binxtils
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/char_count.rake"
    end
  end
end
