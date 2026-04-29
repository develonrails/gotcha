# frozen_string_literal: true

module Gotcha
  module Alerts
    module Channels
      class Slack < Base
        def send_alert(error_event)
          webhook_url = config[:webhook_url]
          return if webhook_url.blank?
          post_webhook(webhook_url, build_payload(error_event))
        end

        private

        def build_payload(error_event)
          {
            channel: config[:channel],
            username: config[:username] || "Gotcha",
            icon_emoji: config[:icon_emoji] || ":bug:",
            attachments: [ {
              color: severity_color(error_event.severity),
              title: error_event.exception_class.to_s,
              title_link: error_url(error_event),
              text: error_event.message.to_s.truncate(500),
              fields: build_fields(error_event),
              footer: "Gotcha | #{error_event.environment}",
              ts: error_event.last_seen_at.to_i
            }.compact ]
          }.compact
        end

        def build_fields(error_event)
          fields = [
            { title: "Occurrences", value: error_event.occurrence_count.to_s, short: true },
            { title: "Severity", value: error_event.severity.upcase, short: true }
          ]
          if error_event.release_version
            fields << { title: "Release", value: error_event.release_version.to_s.truncate(20), short: true }
          end
          if error_event.backtrace_lines.any?
            fields << { title: "Location", value: "`#{error_event.backtrace_lines.first.truncate(80)}`", short: false }
          end
          fields
        end

        def severity_color(severity)
          case severity
          when "error" then "#dc3545"
          when "warning" then "#ffc107"
          when "info" then "#17a2b8"
          else "#6c757d"
          end
        end
      end
    end
  end
end
