# frozen_string_literal: true

class PersistPerformanceJob < ApplicationJob
  queue_as :gotcha

  def perform(event_data)
    event_data = event_data.deep_symbolize_keys
    scrubbed = Gotcha::Processing::DataScrubber.scrub(event_data)
    PerformanceEvent.create_from_event(scrubbed)
  rescue StandardError => e
    Rails.logger.error("[Gotcha] Failed to persist perf event: #{e.message}")
    raise
  end
end
