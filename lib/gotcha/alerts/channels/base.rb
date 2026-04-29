# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Gotcha
  module Alerts
    module Channels
      class Base
        attr_reader :config

        def initialize(config)
          @config = config
        end

        def send_alert(error_event)
          raise NotImplementedError, "#{self.class} must implement #send_alert"
        end

        protected

        def format_error_title(error_event)
          "[#{error_event.severity.upcase}] #{error_event.exception_class}"
        end

        def format_error_message(error_event)
          error_event.message.to_s.truncate(500)
        end

        def format_occurrence_info(error_event)
          error_event.occurrence_count > 1 ? "Occurred #{error_event.occurrence_count} times" : "First occurrence"
        end

        def error_url(error_event)
          base_url = ENV.fetch("GOTCHA_BASE_URL", nil)
          return nil unless base_url
          "#{base_url}/errors/#{error_event.id}"
        end

        def post_webhook(url, payload, headers: {}, read_timeout: 5)
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          http.open_timeout = 5
          http.read_timeout = read_timeout
          request = Net::HTTP::Post.new(uri.request_uri)
          request["Content-Type"] = "application/json"
          headers.each { |key, value| request[key] = value }
          request.body = payload.to_json
          http.request(request)
        rescue StandardError => e
          Gotcha.logger.error("[Gotcha] #{self.class.name.demodulize} alert failed: #{e.message}")
        end
      end
    end
  end
end
