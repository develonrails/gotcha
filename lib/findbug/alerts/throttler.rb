# frozen_string_literal: true

module Findbug
  module Alerts
    class Throttler
      THROTTLE_KEY_PREFIX = "findbug/alert/throttle/"

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
          Findbug.config.alerts.throttle_period
        end
      end
    end
  end
end
