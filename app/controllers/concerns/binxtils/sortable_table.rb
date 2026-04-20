# frozen_string_literal: true

module Binxtils
  module SortableTable
    extend ActiveSupport::Concern

    included do
      before_action :set_period, only: %i[index]

      helper_method :sort_column, :sort_direction, :default_column, :default_direction
    end

    def sort_column
      @sort_column ||= sortable_columns.include?(params[:sort]) ? params[:sort] : default_column
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : default_direction
    end

    def permitted_time_range_columns
      %w[created_at updated_at].freeze
    end

    def current_time_range_column
      permitted_time_range_columns.include?(sort_column) ? sort_column : permitted_time_range_columns.first
    end

    # So they can be overridden
    def default_direction = "desc"

    def default_column = sortable_columns.first
  end
end
