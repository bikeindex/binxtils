# frozen_string_literal: true

require "spec_helper"

# Minimal controller-like object for testing SetPeriod
class SetPeriodTestController
  include Binxtils::SetPeriod

  attr_accessor :params, :session, :cookies

  # Expose ivars for assertions
  attr_reader :period, :start_time, :end_time, :time_range, :render_chart, :timezone, :search_at
  def initialize(params: {}, session: {}, cookies: {})
    @params = params.with_indifferent_access
    @session = session.with_indifferent_access
    @cookies = cookies.with_indifferent_access
  end
end

RSpec.describe Binxtils::SetPeriod do
  let(:params) { {} }
  let(:session) { {} }
  let(:cookies) { {} }
  let(:controller) { SetPeriodTestController.new(params:, session:, cookies:) }

  before { controller.set_period }

  describe "set_period" do
    context "no period param" do
      it "defaults to all" do
        expect(controller.period).to eq "all"
        expect(controller.start_time).to match_time SetPeriodTestController.default_earliest_time
        expect(controller.end_time).to be_within(1).of Time.current
        expect(controller.time_range).to be_a Range
      end
    end

    context "hour" do
      let(:params) { {period: "hour"} }

      it "sets start_time to 1 hour ago" do
        expect(controller.period).to eq "hour"
        expect(controller.start_time).to be_within(2).of(Time.current - 1.hour)
      end
    end

    context "day" do
      let(:params) { {period: "day"} }

      it "sets start_time to beginning of yesterday" do
        expect(controller.period).to eq "day"
        expect(controller.start_time).to match_time(Time.current.beginning_of_day - 1.day)
      end
    end

    context "week" do
      let(:params) { {period: "week"} }

      it "sets start_time to 1 week ago" do
        expect(controller.period).to eq "week"
        expect(controller.start_time).to match_time(Time.current.beginning_of_day - 1.week)
      end
    end

    context "month" do
      let(:params) { {period: "month"} }

      it "sets start_time to 30 days ago" do
        expect(controller.period).to eq "month"
        expect(controller.start_time).to match_time(Time.current.beginning_of_day - 30.days)
      end
    end

    context "year" do
      let(:params) { {period: "year"} }

      it "sets start_time to 1 year ago" do
        expect(controller.period).to eq "year"
        expect(controller.start_time).to match_time(Time.current.beginning_of_day - 1.year)
      end
    end

    context "next_week" do
      let(:params) { {period: "next_week"} }

      it "sets end_time to 1 week from now" do
        expect(controller.period).to eq "next_week"
        expect(controller.start_time).to be_within(1).of(Time.current)
        expect(controller.end_time).to match_time(Time.current.beginning_of_day + 1.week)
      end
    end

    context "next_month" do
      let(:params) { {period: "next_month"} }

      it "sets end_time to 30 days from now" do
        expect(controller.period).to eq "next_month"
        expect(controller.start_time).to be_within(1).of(Time.current)
        expect(controller.end_time).to match_time(Time.current.beginning_of_day + 30.days)
      end
    end

    context "custom with start_time and end_time" do
      let(:params) { {period: "custom", start_time: "2024-01-01", end_time: "2024-06-01"} }

      it "parses both times" do
        expect(controller.period).to eq "custom"
        expect(controller.start_time).to match_time Binxtils::TimeParser.parse("2024-01-01")
        expect(controller.end_time).to match_time Binxtils::TimeParser.parse("2024-06-01")
      end
    end

    context "custom with reversed times" do
      let(:params) { {period: "custom", start_time: "2024-06-01", end_time: "2024-01-01"} }

      it "swaps start and end" do
        expect(controller.start_time).to match_time Binxtils::TimeParser.parse("2024-01-01")
        expect(controller.end_time).to match_time Binxtils::TimeParser.parse("2024-06-01")
      end
    end

    context "custom without start_time" do
      let(:params) { {period: "custom"} }

      it "falls back to set_time_range_from_period" do
        expect(controller.period).to eq "all"
      end
    end

    context "search_at" do
      let(:search_time) { "2024-03-15 12:00:00" }
      let(:params) { {search_at: search_time} }

      it "sets period to custom with offset around search_at" do
        expect(controller.period).to eq "custom"
        parsed = Binxtils::TimeParser.parse(search_time)
        expect(controller.search_at).to match_time parsed
        expect(controller.start_time).to match_time(parsed - 10.minutes)
        expect(controller.end_time).to match_time(parsed + 10.minutes)
      end
    end

    context "search_at with custom offset" do
      let(:search_time) { "2024-03-15 12:00:00" }
      let(:params) { {search_at: search_time, period: "3600"} }

      it "uses period param as offset in seconds" do
        parsed = Binxtils::TimeParser.parse(search_time)
        expect(controller.start_time).to match_time(parsed - 3600.seconds)
        expect(controller.end_time).to match_time(parsed + 3600.seconds)
      end
    end

    context "render_chart" do
      let(:params) { {render_chart: "true"} }

      it "sets render_chart" do
        expect(controller.render_chart).to eq true
      end
    end

    context "invalid period" do
      let(:params) { {period: "garbage"} }

      it "falls back to default" do
        expect(controller.period).to eq "all"
      end
    end
  end

  describe "default_earliest_time" do
    it "defaults to epoch" do
      expect(SetPeriodTestController.default_earliest_time).to eq Time.at(0)
    end
  end

  describe "set_timezone" do
    context "with timezone param" do
      let(:params) { {timezone: "America/Los_Angeles"} }

      it "sets timezone and saves to session" do
        expect(controller.timezone.name).to eq "America/Los_Angeles"
        expect(controller.session[:timezone]).to eq "America/Los_Angeles"
      end
    end

    context "with session timezone" do
      let(:session) { {timezone: "America/New_York"} }

      it "restores timezone from session" do
        expect(controller.timezone.name).to eq "America/New_York"
      end
    end

    context "with cookie timezone" do
      let(:cookies) { {timezone: "America/Denver"} }

      it "reads timezone from cookies" do
        expect(controller.timezone.name).to eq "America/Denver"
      end
    end

    context "with both session and cookie timezones" do
      let(:session) { {timezone: "America/New_York"} }
      let(:cookies) { {timezone: "America/Denver"} }

      it "prefers session over cookie" do
        expect(controller.timezone.name).to eq "America/New_York"
      end
    end

    context "with timezone param and existing cookie" do
      let(:params) { {timezone: "America/Los_Angeles"} }
      let(:cookies) { {timezone: "America/Denver"} }

      it "prefers param over cookie" do
        expect(controller.timezone.name).to eq "America/Los_Angeles"
      end
    end

    context "no timezone info" do
      it "falls back to default_time_zone" do
        expect(controller.timezone).to eq Binxtils::TimeParser.default_time_zone
      end
    end
  end
end
