class Snippet < ApplicationRecord
  include FilterableConcern

  # Default Order
  default_scope { order(name: :asc) }

  # Associations
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  # Validations
  validates_presence_of :name
  validates_length_of :name, maximum: 100
  validates_length_of :filter_id, maximum: 25, allow_nil: true
  validates_format_of :name, with: %r{\A\S*\z}
  validates_uniqueness_of :name
end
