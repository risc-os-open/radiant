module LocalTime
  def adjust_time(time)
    ::Rails.logger.warn("`adjust_time' is deprecated. All time output is now auto-adjusted to Radiant::Configuration['local.timezone'] or the default ActiveRecord time zone.", caller)
    time
  end
end
