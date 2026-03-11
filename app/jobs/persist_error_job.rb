# frozen_string_literal: true

class PersistErrorJob < ApplicationJob
  queue_as :findbug

  def perform(event_data)
    event_data = event_data.deep_symbolize_keys
    scrubbed = Findbug::Processing::DataScrubber.scrub(event_data)
    error_event = ErrorEvent.upsert_from_event(scrubbed)
    Findbug::Alerts::Dispatcher.notify(error_event) if error_event
  rescue StandardError => e
    Rails.logger.error("[Findbug] Failed to persist error: #{e.message}")
    raise
  end
end
