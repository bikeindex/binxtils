# frozen_string_literal: true

module Binxtils
  module ControllerNamespace
    extend ActiveSupport::Concern

    included do
      helper_method :controller_namespace
    end

    def controller_namespace
      return @controller_namespace if defined?(@controller_namespace)
      @controller_namespace = (self.class.module_parent == Object) ? nil : self.class.module_parent.name.underscore
    end
  end
end
