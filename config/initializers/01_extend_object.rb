class Object
  def self.descendants
    self.subclasses # Introduced in Ruby 3.1
  end
  def presence
    return self if present?
  end
end
