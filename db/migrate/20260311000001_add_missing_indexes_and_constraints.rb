# frozen_string_literal: true

class AddMissingIndexesAndConstraints < ActiveRecord::Migration[8.1]
  def change
    # Composite index for dashboard: project-scoped, status-filtered, sorted by last_seen_at
    add_index :gotcha_error_events, [ :project_id, :status, :last_seen_at ],
              name: "idx_error_events_project_status_last_seen"

    # Composite index for project-scoped performance queries
    add_index :gotcha_performance_events, [ :project_id, :captured_at ],
              name: "idx_perf_events_project_captured"

    # Composite index for N+1 filtered queries
    add_index :gotcha_performance_events, [ :project_id, :has_n_plus_one, :captured_at ],
              name: "idx_perf_events_project_n_plus_one_captured"

    # Add CHECK constraints for enum fields
    add_check_constraint :gotcha_error_events,
                         "status IN ('unresolved', 'resolved', 'ignored')",
                         name: "chk_error_events_status"

    add_check_constraint :gotcha_error_events,
                         "severity IN ('error', 'warning', 'info')",
                         name: "chk_error_events_severity"
  end
end
