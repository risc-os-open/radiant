class Admin::ReferencesController < ApplicationController
  def show
    render template: "admin/references/#{params[:type]}", formats: [:html], layout: false
  end
end
