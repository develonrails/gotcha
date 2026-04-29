# frozen_string_literal: true

class UniquifyErrorEventFingerprint < ActiveRecord::Migration[8.1]
  # Adding a unique index on (project_id, fingerprint) so we can use
  # INSERT ... ON CONFLICT for an atomic upsert. Existing duplicates
  # (caused by the prior find_by/save race) are merged: keep the row with
  # the lowest id, sum occurrence_count, take the latest last_seen_at.
  def up
    dedupe_existing_rows

    if index_exists?(:gotcha_error_events, [ :project_id, :fingerprint ], name: "idx_error_events_project_fingerprint")
      remove_index :gotcha_error_events, name: "idx_error_events_project_fingerprint"
    end

    add_index :gotcha_error_events, [ :project_id, :fingerprint ],
              unique: true,
              name: "idx_error_events_project_fingerprint"
  end

  def down
    if index_exists?(:gotcha_error_events, [ :project_id, :fingerprint ], name: "idx_error_events_project_fingerprint")
      remove_index :gotcha_error_events, name: "idx_error_events_project_fingerprint"
    end

    add_index :gotcha_error_events, [ :project_id, :fingerprint ],
              name: "idx_error_events_project_fingerprint"
  end

  private

  def dedupe_existing_rows
    execute <<~SQL.squish
      WITH grouped AS (
        SELECT project_id, fingerprint,
               MIN(id) AS keeper_id,
               SUM(occurrence_count) AS total_count,
               MAX(last_seen_at) AS latest_seen
        FROM gotcha_error_events
        WHERE project_id IS NOT NULL
        GROUP BY project_id, fingerprint
        HAVING COUNT(*) > 1
      )
      UPDATE gotcha_error_events e
      SET occurrence_count = g.total_count,
          last_seen_at = g.latest_seen
      FROM grouped g
      WHERE e.id = g.keeper_id
    SQL

    execute <<~SQL.squish
      DELETE FROM gotcha_error_events e
      USING (
        SELECT project_id, fingerprint, MIN(id) AS keeper_id
        FROM gotcha_error_events
        WHERE project_id IS NOT NULL
        GROUP BY project_id, fingerprint
        HAVING COUNT(*) > 1
      ) g
      WHERE e.project_id = g.project_id
        AND e.fingerprint = g.fingerprint
        AND e.id <> g.keeper_id
    SQL
  end
end
