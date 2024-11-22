class Admin::PreferencesController < ApplicationController
  before_action :load_user

  def initialize
    @controller_name = 'user'
    @template_name = 'preferences'
  end

  def show
    set_standard_body_style
    render :edit
  end

  def edit
    render
  end

  def update
    success = @user.update(User.get_permitted_params_from(params))

    if success
      redirect_to admin_configuration_path
    else
      flash[:error] = t('preferences_controller.error_updating')
      render :edit
    end
  end

  private

    def load_user
      @user = current_user
    end

end
