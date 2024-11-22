# for inclusion into public-facing controllers
#
module Radiant::Pagination::Controller
  def pagination_parameters
    {
      :page  => params[:page ] || 1,
      :limit => params[:items] || Radiant::Configuration['pagination.per_page'] || 20
    }
  end

  def self.included(base)
    base.class_eval {
      helper_method :pagination_parameters
    }
  end
end
