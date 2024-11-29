class String

  # "ThisAnd That And-this And_that" -> :this_and_that_and_this_and_that
  #
  def symbolize
    self.gsub(/[^A-Za-z0-9]+/, "_").gsub(/(^_+|_+$)/, "").underscore.to_sym
  end

  # Differs somewhat from the built-in Rails version.
  #
  #   "ThisAnd That and-this and_that" -> "ThisAnd That And-this And_that" (us)
  #   "ThisAnd That and-this and_that" -> "This And That And This And That" (Rails)
  #
  def titlecase
    self.gsub(/((?:^|\s)[a-z])/) { $1.upcase }
  end

  # *This* is quite like the stock Rails #titleize.
  #
  #   "ThisAnd That and-this and_that" -> "This And That And This And That"
  #
  def to_name(remove_prefix: '', remove_suffix: '')
    self
      .sub(/^#{remove_prefix}/, '')
      .sub(/#{remove_suffix}$/, '')
      .underscore
      .gsub('/', ' ')
      .humanize
      .titlecase
  end

  alias :to_slug   :parameterize
  alias :slugify   :parameterize
  alias :slugerize :parameterize
end
