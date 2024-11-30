# A special case of UsersController, really, with an edit-only ability just for
# the *current* user, which doesn't require admin privileges but also does not
# allow certain things (such as roles) to be changed. For full access, use the
# UsersController via an admin-enabled user login.
#
# The editor view components herein are basically copy-pasted from the admin's
# user edit form, but with some fields removed. Permitted parameters are
# accordingly also narrowed for updates performed herein.
#
class Admin::PreferencesController < ApplicationController
  before_action :load_user

  def edit
    set_standard_body_style
    render
  end

  def update
    success = @user.update(
      params
        .require(:user)
        .permit(User.permitted_unprivileged_params())
    )

    if success
      redirect_to admin_configuration_path()
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
