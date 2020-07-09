# For no good reason that I can discern, Time doesn't expose the internal seconds/nanoseconds representation.
# There are protected methods to get it, but we want it, so let's get it.

struct Time
  @[AlwaysInline]
  def internal_seconds
    @seconds
  end

  @[AlwaysInline]
  def internal_nanoseconds
    @nanoseconds
  end
end
