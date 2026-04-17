# frozen_string_literal: true

require "spec_helper"

class ControllerNamespaceTestBase
  def self.helper_method(*) = nil
end

class ControllerNamespaceTestController < ControllerNamespaceTestBase
  include Binxtils::ControllerNamespace
end

module Admin
  class NamespacedController < ControllerNamespaceTestBase
    include Binxtils::ControllerNamespace
  end
end

module Api
  module V2
    class DeeplyNamespacedController < ControllerNamespaceTestBase
      include Binxtils::ControllerNamespace
    end
  end
end

RSpec.describe Binxtils::ControllerNamespace do
  describe "controller_namespace" do
    context "top-level controller" do
      it "returns nil" do
        expect(ControllerNamespaceTestController.new.controller_namespace).to be_nil
      end
    end

    context "single-level namespace" do
      it "returns the underscored namespace" do
        expect(Admin::NamespacedController.new.controller_namespace).to eq "admin"
      end
    end

    context "nested namespace" do
      it "returns the immediate parent namespace underscored" do
        expect(Api::V2::DeeplyNamespacedController.new.controller_namespace).to eq "api/v2"
      end
    end
  end
end
