require "active_support/concern"

module UserActionObserverConcern
  extend ActiveSupport::Concern

  included do
    after_initialize  ->(obj) { obj.created_by ||= User.current_user }
    before_validation ->(obj) { obj.updated_by   = User.current_user }
  end

  def current_user=(user); self.class.current_user = user; end
  def current_user;        self.class.current_user;        end

  class_methods do
    def current_user=(user); Current.user = user; end # lib/current.rb
    def current_user;        Current.user;        end
  end
end
