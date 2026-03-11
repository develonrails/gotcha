# frozen_string_literal: true

Rails.application.config.after_initialize do
  Findbug.configure do |config|
  config.enabled = true
  config.web_username = ENV["FINDBUG_USERNAME"]
  config.web_password = ENV["FINDBUG_PASSWORD"]
  config.retention_days = 30
  end
end
