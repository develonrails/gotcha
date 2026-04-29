# frozen_string_literal: true

class AlertJob < ApplicationJob
  queue_as :gotcha
  retry_on StandardError, attempts: 3, wait: :polynomially_longer

  def perform(error_event_id)
    error_event = ErrorEvent.find_by(id: error_event_id)
    return unless error_event
    Gotcha::Alerts::Dispatcher.send_alerts(error_event)
  end
end
