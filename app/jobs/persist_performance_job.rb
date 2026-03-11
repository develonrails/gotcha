# frozen_string_literal: true

class PersistPerformanceJob < ApplicationJob
  queue_as :findbug

  def perform(event_data)
    event_data = event_data.deep_symbolize_keys
    scrubbed = Findbug::Processing::DataScrubber.scrub(event_data)
    PerformanceEvent.create_from_event(scrubbed)
  rescue StandardError => e
    Rails.logger.error("[Findbug] Failed to persist perf event: #{e.message}")
    raise
  end
end
