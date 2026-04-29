# frozen_string_literal: true

Rails.application.config.after_initialize do
  Gotcha.configure do |config|
  config.enabled = true
  config.web_username = ENV["GOTCHA_USERNAME"]
  config.web_password = ENV["GOTCHA_PASSWORD"]
  config.retention_days = 30
  end
end
