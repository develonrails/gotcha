# frozen_string_literal: true

class PerformanceController < ApplicationController
  def index
    @since = parse_since(params[:since] || "24h")
    base = scope_to_project(PerformanceEvent)
    @slowest = base.slowest_transactions(since: @since, limit: 20)
    @n_plus_one = base.n_plus_one_hotspots(since: @since, limit: 10)
    @throughput = base.throughput_over_time(since: @since)
    @stats = base.stats_since(@since)
  end

  def show
    @transaction_name = params[:id]
    @since = parse_since(params[:since] || "24h")

    base = scope_to_project(PerformanceEvent)
    @events = base.where(transaction_name: @transaction_name)
                  .where("captured_at >= ?", @since)
                  .recent.limit(100)
    @stats = base.aggregate_for(@transaction_name, since: @since)
    @slowest_requests = @events.order(duration_ms: :desc).limit(10)
    @n_plus_one_requests = @events.where(has_n_plus_one: true).limit(10)
  end
end
