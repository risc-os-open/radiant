module LocalTime
  def adjust_time(time)
    ::ActiveSupport::Deprecation.warn("`adjust_time' is deprecated. All time output is now auto-adjusted to Radiant::Configuration['local.timezone'] or the default ActiveRecord time zone.", caller)
    time
  end
end
