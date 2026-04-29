# frozen_string_literal: true

class PersistErrorJob < ApplicationJob
  queue_as :gotcha

  def perform(event_data)
    event_data = event_data.deep_symbolize_keys
    scrubbed = Gotcha::Processing::DataScrubber.scrub(event_data)
    error_event = ErrorEvent.upsert_from_event(scrubbed)
    Gotcha::Alerts::Dispatcher.notify(error_event) if error_event
  rescue StandardError => e
    Rails.logger.error("[Gotcha] Failed to persist error: #{e.message}")
    raise
  end
end
