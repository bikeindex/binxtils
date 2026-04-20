# frozen_string_literal: true

require "spec_helper"
require "action_controller"
require "action_dispatch"

module Admin
  class UsersController < ActionController::Base; end
end

class OtherController < ActionController::Base; end

TEST_ROUTES = ActionDispatch::Routing::RouteSet.new.tap do |routes|
  routes.draw do
    get "/admin/users", to: "admin/users#index"
    get "/admin/users/new", to: "admin/users#new"
    get "/other", to: "other#index"
  end
end

class NavHelperTestContext
  include Binxtils::NavHelper

  attr_accessor :request, :current_url

  def initialize(current_url:)
    @current_url = current_url
    @request = Struct.new(:url).new(current_url)
  end

  def current_page?(path)
    URI.parse(@current_url).path == path
  end
end

RSpec.describe Binxtils::NavHelper do
  let(:helper) { NavHelperTestContext.new(current_url: "http://example.com/admin/users/new") }

  before do
    fake_app = Object.new
    fake_app.define_singleton_method(:routes) { TEST_ROUTES }
    allow(Rails).to receive(:application).and_return(fake_app)
  end

  describe "current_page_active?" do
    context "match_controller false" do
      it "matches only the exact current path" do
        expect(helper.current_page_active?("/admin/users/new")).to eq true
        expect(helper.current_page_active?("/admin/users")).to eq false
        expect(helper.current_page_active?("/other")).to eq false
      end
    end

    context "match_controller true, same controller different action" do
      it "returns true" do
        expect(helper.current_page_active?("/admin/users", true)).to eq true
      end
    end

    context "match_controller true, different controller" do
      it "returns false" do
        expect(helper.current_page_active?("/other", true)).to eq false
      end
    end

    context "match_controller true, unknown path" do
      it "returns false without raising" do
        expect(helper.current_page_active?("/does/not/exist", true)).to eq false
      end
    end
  end
end
