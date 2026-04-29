# frozen_string_literal: true

class RenameFindbugTablesToGotcha < ActiveRecord::Migration[8.1]
  RENAMES = {
    findbug_alert_channels: :gotcha_alert_channels,
    findbug_error_events: :gotcha_error_events,
    findbug_performance_events: :gotcha_performance_events,
    findbug_projects: :gotcha_projects
  }.freeze

  def up
    RENAMES.each do |old_name, new_name|
      next unless table_exists?(old_name)
      next if table_exists?(new_name)
      rename_table old_name, new_name
    end
  end

  def down
    RENAMES.each do |old_name, new_name|
      next unless table_exists?(new_name)
      next if table_exists?(old_name)
      rename_table new_name, old_name
    end
  end
end
