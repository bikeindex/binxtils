# frozen_string_literal: true

module Binxtils
  module SetPeriod
    extend ActiveSupport::Concern

    DEFAULT_EARLIEST_TIME = Time.at(1134972000) # Earliest bike created at
    PERIOD_TYPES = %w[hour day month year week all next_week next_month].freeze

    # For setting periods, particularly for graphing
    def set_period
      @timezone ||= Time.zone
      # Set time period
      @period ||= params[:period]
      if @period == "custom"
        if params[:start_time].present?
          @start_time = Binxtils::TimeParser.parse(params[:start_time], @timezone)
          @end_time = Binxtils::TimeParser.parse(params[:end_time], @timezone) || latest_period_date
          if @start_time > @end_time
            new_end_time = @start_time
            @start_time = @end_time
            @end_time = new_end_time
          end
        else
          set_time_range_from_period
        end
      elsif params[:search_at].present?
        @period = "custom"
        @search_at = Binxtils::TimeParser.parse(params[:search_at], @timezone)
        offset = params[:period].present? ? params[:period].to_i : 10.minutes.to_i
        @start_time = @search_at - offset
        @end_time = @search_at + offset
      else
        set_time_range_from_period
      end
      # Add this render_chart in here so we don't have to define it in all the controllers
      @render_chart = Binxtils::InputNormalizer.boolean(params[:render_chart])
      @time_range = @start_time..@end_time
    end

    private

    def set_time_range_from_period
      @period = default_period unless PERIOD_TYPES.include?(@period)

      case @period
      when "hour"
        @start_time = Time.current - 1.hour
      when "day"
        @start_time = Time.current.beginning_of_day - 1.day
      when "month"
        @start_time = Time.current.beginning_of_day - 30.days
      when "year"
        @start_time = Time.current.beginning_of_day - 1.year
      when "week"
        @start_time = Time.current.beginning_of_day - 1.week
      when "next_month"
        @start_time ||= Time.current
        @end_time = Time.current.beginning_of_day + 30.days
      when "next_week"
        @start_time = Time.current
        @end_time = Time.current.beginning_of_day + 1.week
      when "all"
        @start_time = earliest_period_date
        @end_time = latest_period_date
      end
      @end_time ||= Time.current
    end

    # Separate method so it can be overridden on per controller basis
    def default_period
      "all"
    end

    # Separate method so it can be overridden, specifically in invoices
    def latest_period_date
      Time.current
    end

    # Separate method so it can be overridden on per controller basis
    def earliest_period_date
      DEFAULT_EARLIEST_TIME
    end

    def set_timezone
      return true if @timezone.present?

      if params[:timezone].present?
        @timezone = Binxtils::TimeZoneParser.parse(params[:timezone])
        session[:timezone] = @timezone&.name
      end

      if session[:timezone].present?
        @timezone ||= Binxtils::TimeZoneParser.parse(session[:timezone])
        Time.zone = @timezone
      end

      @timezone ||= Binxtils::TimeParser.default_time_zone
    end
  end
end
