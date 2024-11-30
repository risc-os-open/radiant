class PageField < ApplicationRecord
  validates_presence_of :name

  def self.permitted_params
    [
      :name,
      :content,
    ]
  end
end
