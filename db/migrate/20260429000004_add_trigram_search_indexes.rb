# frozen_string_literal: true

class AddTrigramSearchIndexes < ActiveRecord::Migration[8.1]
  # The error search uses ILIKE '%X%' on exception_class and message; leading
  # wildcards prevent B-tree use, so the optimizer falls back to a full scan.
  # GIN indexes with gin_trgm_ops let Postgres serve those queries from an
  # index. Requires the pg_trgm extension (CREATE EXTENSION needs superuser
  # on first run; safe-no-op afterwards).
  def up
    enable_extension :pg_trgm

    add_index :gotcha_error_events, :exception_class,
              using: :gin, opclass: :gin_trgm_ops,
              name: "idx_gotcha_error_events_exception_class_trgm"

    add_index :gotcha_error_events, :message,
              using: :gin, opclass: :gin_trgm_ops,
              name: "idx_gotcha_error_events_message_trgm"
  end

  def down
    if index_exists?(:gotcha_error_events, :exception_class, name: "idx_gotcha_error_events_exception_class_trgm")
      remove_index :gotcha_error_events, name: "idx_gotcha_error_events_exception_class_trgm"
    end
    if index_exists?(:gotcha_error_events, :message, name: "idx_gotcha_error_events_message_trgm")
      remove_index :gotcha_error_events, name: "idx_gotcha_error_events_message_trgm"
    end
    # Leave the extension enabled — other consumers may rely on it.
  end
end
