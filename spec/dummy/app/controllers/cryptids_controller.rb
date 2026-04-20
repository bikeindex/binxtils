# frozen_string_literal: true

class CryptidsController < ApplicationController
  include Binxtils::SortableTable
  include Binxtils::SetPeriod

  def index
    @cryptids = Cryptid.where(first_seen: @time_range)
      .order(sort_column => sort_direction)
  end

  def sortable_columns
    %w[name region sightings first_seen]
  end

  def default_column = "sightings"

  def permitted_time_range_columns
    %w[first_seen created_at updated_at].freeze
  end

  def earliest_period_date
    Time.utc(1800, 1, 1)
  end
end
