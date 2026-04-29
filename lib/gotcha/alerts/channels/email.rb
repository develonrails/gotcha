# frozen_string_literal: true

module Gotcha
  module Alerts
    module Channels
      class Email < Base
        def send_alert(error_event)
          recipients = config[:recipients]
          return if recipients.blank?

          if defined?(ActionMailer::Base)
            GotchaMailer.error_alert(error_event, recipients).deliver_later
          else
            Gotcha.logger.warn("[Gotcha] ActionMailer not available for email alerts")
          end
        end
      end
    end
  end
end
