# frozen_string_literal: true

require "spec_helper"
require "action_controller"

# Minimal helper-like object for testing SortableHelper
class SortableHelperTestContext
  include Binxtils::SortableHelper

  attr_accessor :params

  def initialize(params: {})
    @params = ActionController::Parameters.new(params)
  end

  def default_column = "id"
  def default_direction = "desc"
end

RSpec.describe Binxtils::SortableHelper do
  let(:params) { {} }
  let(:helper) { SortableHelperTestContext.new(params:) }

  describe "default_search_keys" do
    it "returns BASE_SEARCH_KEYS" do
      expect(helper.default_search_keys).to eq Binxtils::SortableHelper::BASE_SEARCH_KEYS
    end
  end

  describe "sortable_search_params" do
    context "with permitted params" do
      let(:params) { {sort: "name", direction: "asc", query: "bike"} }

      it "permits known keys" do
        result = helper.sortable_search_params
        expect(result[:sort]).to eq "name"
        expect(result[:direction]).to eq "asc"
        expect(result[:query]).to eq "bike"
      end
    end

    context "with search_ prefixed params" do
      let(:params) { {search_status: "active", query: "test"} }

      it "permits search_ params dynamically" do
        result = helper.sortable_search_params
        expect(result[:search_status]).to eq "active"
        expect(result[:query]).to eq "test"
      end
    end

    context "with unknown params" do
      let(:params) { {sort: "name", secret: "value"} }

      it "filters out unknown keys" do
        result = helper.sortable_search_params
        expect(result[:sort]).to eq "name"
        expect(result[:secret]).to be_nil
      end
    end

    context "memoization" do
      let(:params) { {sort: "name"} }

      it "returns same object on repeated calls" do
        first = helper.sortable_search_params
        second = helper.sortable_search_params
        expect(first).to equal second
      end
    end
  end

  describe "sortable_search_params?" do
    context "no params" do
      it "returns false" do
        expect(helper.sortable_search_params?).to eq false
      end
    end

    context "with query param" do
      let(:params) { {query: "bike"} }

      it "returns true" do
        expect(helper.sortable_search_params?).to eq true
      end
    end

    context "with only sort params" do
      let(:params) { {sort: "name", direction: "asc"} }

      it "returns false" do
        expect(helper.sortable_search_params?).to eq false
      end
    end

    context "with non-all period" do
      let(:params) { {period: "month"} }

      it "returns true" do
        expect(helper.sortable_search_params?).to eq true
      end
    end

    context "with all period" do
      let(:params) { {period: "all"} }

      it "returns false" do
        expect(helper.sortable_search_params?).to eq false
      end
    end

    context "with period excepted" do
      let(:params) { {period: "month"} }

      it "returns false" do
        expect(helper.sortable_search_params?(except: [:period])).to eq false
      end
    end
  end

  describe "sortable_params" do
    context "with blank values" do
      let(:params) { {sort: "name", query: ""} }

      it "strips blank values" do
        result = helper.sortable_params
        expect(result[:sort]).to eq "name"
        expect(result.key?("query")).to eq false
      end
    end

    context "with default sort values" do
      let(:params) { {sort: "id", query: "bike"} }

      it "strips default sort column" do
        result = helper.sortable_params
        expect(result.key?("sort")).to eq false
        expect(result["query"]).to eq "bike"
      end
    end
  end
end
