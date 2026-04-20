# frozen_string_literal: true

module Binxtils
  class Engine < ::Rails::Engine
    isolate_namespace Binxtils

    rake_tasks do
      load "tasks/char_count.rake"
    end
  end
end
