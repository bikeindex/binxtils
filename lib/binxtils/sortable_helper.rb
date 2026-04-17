# frozen_string_literal: true

module Binxtils
  module SortableHelper
    extend ActiveSupport::Concern

    BASE_SEARCH_KEYS = [
      :direction, :sort, # sorting params
      :period, :start_time, :end_time, :render_chart, # Time period params
      :user_id, :query, :per_page # General search params
    ].freeze

    mattr_accessor :extra_search_keys, default: []

    # Set defaults, required for testing
    def sort_column = "id"
    def sort_direction = "desc"

    def default_search_keys
      BASE_SEARCH_KEYS + Binxtils::SortableHelper.extra_search_keys
    end

    def sortable(column, title = nil, html_options = {}, &block)
      if title.is_a?(Hash) # If title is a hash, it wasn't passed
        html_options = title
        title = nil
      end
      title ||= column.gsub(/_(id|at)\z/, "").titleize

      # Check for render_sortable - otherwise default to rendering
      render_sortable = html_options.key?(:render_sortable) ? html_options[:render_sortable] : !html_options[:skip_sortable]
      return title unless render_sortable

      html_options[:class] = "#{html_options[:class]} sortable-link"
      direction = (column == sort_column && sort_direction == "desc") ? "asc" : "desc"

      if column == sort_column
        html_options[:class] += " active"
        span_content = (direction == "asc") ? "\u2193" : "\u2191"
      end

      link_to(sortable_url(column, direction), html_options) do
        concat(block_given? ? capture(&block) : title.html_safe)
        concat(content_tag(:span, span_content, class: "sortable-direction"))
      end
    end

    def sortable_search_params?(except: [])
      except_keys = %i[direction sort period per_page] + except
      s_params = sortable_search_params.except(*except_keys).values.reject(&:blank?).any?

      return true if s_params
      return false if except.map(&:to_s).include?("period")

      params[:period].present? && params[:period] != "all"
    end

    def sortable_params
      @sortable_params ||= sortable_search_params.as_json.filter_map do |k, v|
        next if v.blank? || k == "sort" && v == default_column ||
          k == "direction" && v == default_direction
        [k, v]
      end.to_h.with_indifferent_access
    end

    def sortable_search_params
      return @sortable_search_params if defined?(@sortable_search_params)

      search_param_keys = params.keys.select { |k| k.to_s.start_with?("search_") } # match params starting with search_
      @sortable_search_params = params.permit(*(default_search_keys | search_param_keys))
    end

    private

    # This is a separate method purely for testing purposes, so it can be stubbed
    def sortable_url(sort, direction)
      url_for(sortable_search_params.merge(sort:, direction:))
    end
  end
end
