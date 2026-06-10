# frozen_string_literal: true

require "spec_helper"
require "action_controller"
require "action_view/helpers"
require "action_view/buffers"

# Minimal helper-like object for testing SortableHelper
class SortableHelperTestContext
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::CaptureHelper
  include Binxtils::SortableHelper

  attr_accessor :params, :output_buffer

  def initialize(params: {})
    @params = ActionController::Parameters.new(params)
    @output_buffer = ActionView::OutputBuffer.new
  end

  def default_column = "id"
  def default_direction = "desc"
end

RSpec.describe Binxtils::SortableHelper do
  let(:passed_params) { {} }
  let(:helper) { SortableHelperTestContext.new(params: passed_params) }

  describe "sortable_search_params" do
    context "no sortable_search_params" do
      let(:passed_params) { {party: "stuff"} }

      it "returns an empty hash" do
        expect(helper.sortable_search_params.to_unsafe_h).to eq({})
      end
    end

    context "search_ prefixed params" do
      let(:passed_params) { {search_email: "stttt"} }

      it "includes search_ params" do
        expect(helper.sortable_search_params.to_unsafe_h).to eq(passed_params.as_json)
      end
    end

    context "direction, sort" do
      let(:passed_params) { {direction: "asc", sort: "stolen", party: "long"} }
      let(:target) { {direction: "asc", sort: "stolen"} }

      it "returns target hash" do
        expect(helper.sortable_search_params.to_unsafe_h).to eq(target.as_json)
      end
    end

    context "direction, sort, search param" do
      let(:time) { Time.current.to_i }
      let(:passed_params) { {direction: "asc", sort: "stolen", party: "long", search_stuff: "xxx", user_id: 21, start_time: time, end_time: time, period: "custom"} }
      let(:target) { {direction: "asc", sort: "stolen", search_stuff: "xxx", user_id: 21, start_time: time, end_time: time, period: "custom"} }

      it "returns target hash" do
        expect(helper.sortable_search_params.to_unsafe_h).to eq(target.as_json)
      end
    end

    context "direction, sort, period: all" do
      let(:passed_params) { {direction: "asc", sort: "stolen", period: "all"} }

      it "returns falsey for sortable_search_params?" do
        expect(helper.sortable_search_params?).to be_falsey
      end
    end

    context "direction, sort, period: week" do
      let(:passed_params) { {direction: "asc", sort: "stolen", period: "week"} }

      it "returns truthy for sortable_search_params?" do
        expect(helper.sortable_search_params?).to be_truthy
      end
    end
  end

  describe "sortable_search_params?" do
    context "with period excepted" do
      let(:passed_params) { {period: "month"} }

      it "returns false" do
        expect(helper.sortable_search_params?(except: [:period])).to eq false
      end
    end
  end

  describe "sortable_params" do
    context "with blank values" do
      let(:passed_params) { {sort: "name", query: ""} }

      it "strips blank values" do
        result = helper.sortable_params
        expect(result[:sort]).to eq "name"
        expect(result.key?("query")).to eq false
      end
    end

    context "with default sort values" do
      let(:passed_params) { {sort: "id", query: "bike"} }

      it "strips default sort column" do
        result = helper.sortable_params
        expect(result.key?("sort")).to eq false
        expect(result["query"]).to eq "bike"
      end
    end

    context "with default direction" do
      let(:passed_params) { {direction: "desc", query: "bike"} }

      it "strips default direction" do
        result = helper.sortable_params
        expect(result.key?("direction")).to eq false
        expect(result["query"]).to eq "bike"
      end
    end
  end

  describe "#sortable" do
    before { allow(helper).to receive(:sortable_url).and_return("/") }

    context "skip_sortable is true" do
      it "returns only the title string" do
        result = helper.sortable("name", "Full Name", skip_sortable: true)
        expect(result).to eq("Full Name")
      end
    end

    context "render_sortable is false" do
      it "returns only the title string" do
        result = helper.sortable("name", "Full Name", render_sortable: false)
        expect(result).to eq("Full Name")
      end
    end

    context "render_sortable is true or default" do
      it "generates a link with sortable class" do
        result = helper.sortable("email")
        expect(result).to match(/class=..?sortable-link/)
        expect(result).to include("Email")
      end

      it "preserves existing CSS classes" do
        result = helper.sortable("name", "Name", class: "existing-class")
        expect(result).to match(/class=..?existing-class sortable-link/)
      end

      it "includes data attributes and other html options" do
        result = helper.sortable("email", "Email", {data: {turbo: false}, id: "sort-link"})
        expect(result).to include('data-turbo="false"')
        expect(result).to include('id="sort-link"')
      end
    end

    context "with render_sortable: true" do
      it "doesn't render the control option as an HTML attribute" do
        result = helper.sortable("name", "Name", render_sortable: true)
        expect(result).to match(/class=..?sortable-link/)
        expect(result).to_not include("render_sortable")
      end
    end

    context "with skip_sortable: false" do
      it "doesn't render the control option as an HTML attribute" do
        expect(helper.sortable("name", "Name", skip_sortable: false)).to_not include("skip_sortable")
      end
    end

    context "with a reused html_options hash" do
      let(:html_options) { {class: "th-link"} }

      it "doesn't mutate the caller's hash" do
        first_link = helper.sortable("name", "Name", html_options)
        second_link = helper.sortable("email", "Email", html_options)
        expect(html_options).to eq({class: "th-link"})
        expect(first_link.scan("sortable-link").count).to eq 1
        expect(second_link.scan("sortable-link").count).to eq 1
      end
    end

    context "active sort column" do
      it "adds the active class" do
        expect(helper.sortable("id")).to match(/class=..?sortable-link active/)
      end
    end

    context "title with plain text" do
      it "renders the title unchanged" do
        expect(helper.sortable("name", "Full Name")).to include("Full Name")
        expect(helper.sortable("name", "Manufacturer (other)")).to include("Manufacturer (other)")
      end
    end

    context "title with HTML characters" do
      it "escapes the title" do
        result = helper.sortable("name", "<script>alert()</script>")
        expect(result).to_not include("<script>")
        expect(result).to include("&lt;script&gt;alert()&lt;/script&gt;")

        expect(helper.sortable("name", "Bikes & Skis")).to include("Bikes &amp; Skis")
      end

      it "renders HTML passed as a block" do
        result = helper.sortable("name") { "<em>Name</em>".html_safe }
        expect(result).to include("<em>Name</em>")
      end
    end

    context "title not passed" do
      it "generates title from column name" do
        expect(helper.sortable("created_at")).to include("Created")
        expect(helper.sortable("user_id")).to include("User")
      end
    end

    context "with a block" do
      it "renders the block content" do
        result = helper.sortable("name") { "Custom Content" }
        expect(result).to include("Custom Content")
      end
    end
  end

  describe "default_search_keys" do
    context "without extra_search_keys" do
      it "returns BASE_SEARCH_KEYS" do
        expect(helper.default_search_keys).to eq Binxtils::SortableHelper::BASE_SEARCH_KEYS
      end
    end

    context "with extra_search_keys set" do
      around do |example|
        original = Binxtils::SortableHelper.extra_search_keys
        Binxtils::SortableHelper.extra_search_keys = [:organization_id, {query_items: []}]
        example.run
        Binxtils::SortableHelper.extra_search_keys = original
      end

      it "appends extra keys to BASE_SEARCH_KEYS" do
        expect(helper.default_search_keys).to eq(
          Binxtils::SortableHelper::BASE_SEARCH_KEYS + [:organization_id, {query_items: []}]
        )
      end

      context "with matching search params" do
        let(:passed_params) { {organization_id: 7, query_items: ["a", "b"], other: "nope"} }

        it "permits the extra keys in sortable_search_params" do
          expect(helper.sortable_search_params.to_unsafe_h).to eq(
            {"organization_id" => 7, "query_items" => ["a", "b"]}
          )
        end
      end
    end
  end
end
