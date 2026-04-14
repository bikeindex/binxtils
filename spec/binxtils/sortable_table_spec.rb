# frozen_string_literal: true

require "spec_helper"

# Minimal controller-like base with Rails stubs
class SortableTableTestBase
  def self.before_action(*) = nil
  def self.helper_method(*) = nil
end

class SortableTableTestController < SortableTableTestBase
  include Binxtils::SortableTable

  attr_accessor :params

  def initialize(params: {})
    @params = params.with_indifferent_access
  end

  def sortable_columns
    %w[created_at updated_at name]
  end
end

RSpec.describe Binxtils::SortableTable do
  let(:params) { {} }
  let(:controller) { SortableTableTestController.new(params:) }

  describe "sort_column" do
    context "no param" do
      it "returns default_column" do
        expect(controller.sort_column).to eq "created_at"
      end
    end

    context "valid sort param" do
      let(:params) { {sort: "name"} }

      it "returns the param value" do
        expect(controller.sort_column).to eq "name"
      end
    end

    context "invalid sort param" do
      let(:params) { {sort: "nonexistent"} }

      it "falls back to default_column" do
        expect(controller.sort_column).to eq "created_at"
      end
    end
  end

  describe "sort_direction" do
    context "no param" do
      it "returns default_direction" do
        expect(controller.sort_direction).to eq "desc"
      end
    end

    context "asc" do
      let(:params) { {direction: "asc"} }

      it "returns asc" do
        expect(controller.sort_direction).to eq "asc"
      end
    end

    context "invalid direction" do
      let(:params) { {direction: "sideways"} }

      it "falls back to default_direction" do
        expect(controller.sort_direction).to eq "desc"
      end
    end
  end

  describe "default_column" do
    it "returns first sortable column" do
      expect(controller.default_column).to eq "created_at"
    end
  end

  describe "current_time_range_column" do
    context "sort_column is a time range column" do
      let(:params) { {sort: "updated_at"} }

      it "returns sort_column" do
        expect(controller.current_time_range_column).to eq "updated_at"
      end
    end

    context "sort_column is not a time range column" do
      let(:params) { {sort: "name"} }

      it "returns first permitted time range column" do
        expect(controller.current_time_range_column).to eq "created_at"
      end
    end
  end

  describe "permitted_time_range_columns" do
    it "returns created_at and updated_at" do
      expect(controller.permitted_time_range_columns).to eq %w[created_at updated_at]
    end
  end
end
