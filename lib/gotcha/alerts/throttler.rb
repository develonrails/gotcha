# frozen_string_literal: true

module Gotcha
  module Alerts
    class Throttler
      THROTTLE_KEY_PREFIX = "gotcha/alert/throttle/"

      class << self
        def throttled?(fingerprint)
          Rails.cache.exist?(throttle_key(fingerprint))
        rescue StandardError
          false
        end

        def record(fingerprint)
          Rails.cache.write(throttle_key(fingerprint), Time.now.utc.iso8601, expires_in: throttle_period)
        rescue StandardError
          nil
        end

        def clear(fingerprint)
          Rails.cache.delete(throttle_key(fingerprint))
        rescue StandardError
          nil
        end

        private

        def throttle_key(fingerprint)
          "#{THROTTLE_KEY_PREFIX}#{fingerprint}"
        end

        def throttle_period
          Gotcha.config.alerts.throttle_period
        end
      end
    end
  end
end
