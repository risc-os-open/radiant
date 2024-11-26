class PagePart < ApplicationRecord
  include FilterableConcern

  # Default Order
  default_scope { order(name: :asc) }

  # Associations
  belongs_to :page

  # Validations
  validates_presence_of :name
  validates_length_of :name, maximum: 100
  validates_length_of :filter_id, maximum: 25, allow_nil: true

  def after_initialize
    self.filter_id ||= Radiant::Configuration['defaults.page.filter'] if new_record?
  end
end
