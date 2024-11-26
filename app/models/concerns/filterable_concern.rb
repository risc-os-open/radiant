require "active_support/concern"

module FilterableConcern
  extend ActiveSupport::Concern

  def filter
    identifier = self.filter_id
    identifier = Radiant::Configuration['defaults.page.filter'] if identifier.blank?
    identifier = 'Text'                                         if identifier.blank?

    "::Filters::#{identifier}Filter".constantize
  end
end
