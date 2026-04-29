# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @stats = calculate_stats
    @recent_errors = scope_to_project(ErrorEvent).unresolved.recent.limit(10)
    @slowest_endpoints = scope_to_project(PerformanceEvent).slowest_transactions(since: 24.hours.ago, limit: 5)
  end

  def health
    status = {
      status: "ok",
      version: Gotcha::VERSION,
      database: ErrorEvent.connection.active? ? "ok" : "error"
    }
    render json: status
  rescue StandardError => e
    render json: { status: "error", message: e.message }, status: :internal_server_error
  end

  def stats
    render json: calculate_stats
  end

  private

  def calculate_stats
    now_24h = 24.hours.ago
    now_7d = 7.days.ago

    errors = scope_to_project(ErrorEvent)
    error_counts = errors.pick(
      Arel.sql("COUNT(*)"),
      Arel.sql("COUNT(*) FILTER (WHERE status = 'unresolved')"),
      Arel.sql(ErrorEvent.sanitize_sql([ "COUNT(*) FILTER (WHERE created_at >= ?)", now_24h ])),
      Arel.sql(ErrorEvent.sanitize_sql([ "COUNT(*) FILTER (WHERE created_at >= ?)", now_7d ]))
    )
    total, unresolved, last_24h, last_7d = error_counts

    perf = scope_to_project(PerformanceEvent)
    perf_counts = perf.pick(
      Arel.sql("COUNT(*)"),
      Arel.sql(PerformanceEvent.sanitize_sql([ "COUNT(*) FILTER (WHERE captured_at >= ?)", now_24h ])),
      Arel.sql(PerformanceEvent.sanitize_sql([ "AVG(duration_ms) FILTER (WHERE captured_at >= ?)", now_24h ])),
      Arel.sql(PerformanceEvent.sanitize_sql([ "COUNT(*) FILTER (WHERE has_n_plus_one AND captured_at >= ?)", now_24h ]))
    )
    perf_total, perf_24h, avg_duration, n_plus_one = perf_counts

    {
      errors: { total: total, unresolved: unresolved, last_24h: last_24h, last_7d: last_7d },
      performance: {
        total: perf_total,
        last_24h: perf_24h,
        avg_duration: avg_duration&.round(2) || 0,
        n_plus_one_count: n_plus_one
      },
      timestamp: Time.current.iso8601
    }
  end
end
