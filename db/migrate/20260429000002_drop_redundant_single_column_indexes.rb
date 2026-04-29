# frozen_string_literal: true

class DropRedundantSingleColumnIndexes < ActiveRecord::Migration[8.1]
  # The single-column indexes on (exception_class) and (status) are subsumed
  # by the leading column of the composite indexes (exception_class, created_at)
  # and (status, last_seen_at). Dropping them removes write amplification on
  # every error_event insert/update without changing query plans.
  def up
    if index_exists?(:gotcha_error_events, :exception_class, name: "index_gotcha_error_events_on_exception_class")
      remove_index :gotcha_error_events, name: "index_gotcha_error_events_on_exception_class"
    end
    if index_exists?(:gotcha_error_events, :status, name: "index_gotcha_error_events_on_status")
      remove_index :gotcha_error_events, name: "index_gotcha_error_events_on_status"
    end
  end

  def down
    add_index :gotcha_error_events, :exception_class, name: "index_gotcha_error_events_on_exception_class"
    add_index :gotcha_error_events, :status, name: "index_gotcha_error_events_on_status"
  end
end
