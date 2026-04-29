# frozen_string_literal: true

class Project < ApplicationRecord
  self.table_name = "gotcha_projects"

  has_many :error_events, dependent: :destroy
  has_many :performance_events, dependent: :destroy

  RETENTION_OPTIONS = [ 30, 60, 90, 180, 365 ].freeze
  DSN_CACHE_TTL = 5.minutes

  validates :name, presence: true, uniqueness: true
  validates :dsn_key, presence: true, uniqueness: true
  validates :retention_days, inclusion: { in: RETENTION_OPTIONS }

  before_validation :generate_dsn_key, on: :create
  after_commit :clear_dsn_cache

  def self.dsn_cache_key(project_id)
    "gotcha:project:dsn:#{project_id}"
  end

  def self.cached_dsn_key_for(project_id)
    Rails.cache.fetch(dsn_cache_key(project_id), expires_in: DSN_CACHE_TTL) do
      where(id: project_id).pick(:dsn_key)
    end
  end

  def dsn(host: ENV.fetch("GOTCHA_HOST", "localhost:3000"))
    "http://#{dsn_key}@#{host}/#{id}"
  end

  def event_counts
    errors, perf = self.class.where(id: id).pick(
      Arel.sql("(SELECT COUNT(*) FROM gotcha_error_events WHERE project_id = gotcha_projects.id)"),
      Arel.sql("(SELECT COUNT(*) FROM gotcha_performance_events WHERE project_id = gotcha_projects.id)")
    )
    { errors: errors.to_i, performance: perf.to_i }
  end

  private

  def generate_dsn_key
    self.dsn_key ||= SecureRandom.hex(16)
  end

  def clear_dsn_cache
    Rails.cache.delete(self.class.dsn_cache_key(id))
  end
end
