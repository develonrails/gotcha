# frozen_string_literal: true

module Gotcha
  module Alerts
    module Channels
      class Webhook < Base
        def send_alert(error_event)
          url = config[:url]
          return if url.blank?

          payload = build_payload(error_event)
          custom_headers = config[:headers] || {}

          if config[:method]&.upcase == "PUT"
            put_webhook(url, payload, headers: custom_headers)
          else
            post_webhook(url, payload, headers: custom_headers, read_timeout: 10)
          end
        end

        private

        def build_payload(error_event)
          {
            event_type: "error",
            timestamp: Time.now.utc.iso8601,
            gotcha_version: Gotcha::VERSION,
            error: {
              id: error_event.id,
              fingerprint: error_event.fingerprint,
              exception_class: error_event.exception_class,
              message: error_event.message,
              severity: error_event.severity,
              status: error_event.status,
              handled: error_event.handled,
              occurrence_count: error_event.occurrence_count,
              first_seen_at: error_event.first_seen_at&.iso8601,
              last_seen_at: error_event.last_seen_at&.iso8601,
              environment: error_event.environment,
              release: error_event.release_version,
              backtrace: error_event.backtrace_lines,
              context: error_event.context,
              url: error_url(error_event)
            }
          }
        end

        def put_webhook(url, payload, headers: {})
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          http.open_timeout = 5
          http.read_timeout = 10
          request = Net::HTTP::Put.new(uri.request_uri)
          request["Content-Type"] = "application/json"
          headers.each { |key, value| request[key] = value }
          request.body = payload.to_json
          http.request(request)
        rescue StandardError => e
          Gotcha.logger.error("[Gotcha] Webhook alert failed: #{e.message}")
        end
      end
    end
  end
end
