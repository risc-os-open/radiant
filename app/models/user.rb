require 'digest/sha1'

class User < ApplicationRecord
  include UserActionObserverConcern

  has_many :pages, :foreign_key => :created_by_id

  # Default Order
  default_scope { order(name: :asc) }

  # Associations
  belongs_to :created_by, :class_name => 'User', optional: true
  belongs_to :updated_by, :class_name => 'User', optional: true

  # Validations
  validates_presence_of :created_by, if: -> () { User.count > 0 }
  validates_presence_of :updated_by, if: -> () { User.count > 0 }

  validates_uniqueness_of :login

  validates_confirmation_of :password, :if => :confirm_password?

  validates_presence_of :name, :login
  validates_presence_of :password, :password_confirmation, :if => :new_record?

  validates_format_of :email, :allow_nil => true, :with => /\A$|^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  validates_length_of :name, :maximum => 100, :allow_nil => true
  validates_length_of :login, :within => 3..40, :allow_nil => true
  validates_length_of :password, :within => 5..40, :allow_nil => true, :if => :validate_length_of_password?
  validates_length_of :email, :maximum => 255, :allow_nil => true

  attr_writer :confirm_password

  # This is used by PreferencesController externally, since it does not lean on
  # Admin::ResourcesController to do its work. See also ::permitted_params.
  #
  def self.permitted_unprivileged_params
    [
      :lock_version,
      :name,
      :email,
      :login,
      :password,
      :password_confirmation,
      :locale
    ]
  end

  # This is used by Admin::UsersController (via Admin::ResourcesController) and
  # that controller is admin-access only. It allows a wider range of parameters
  # to be altered. A regular user should not, for example, be allowed to set
  # themselves as an admin! See also ::permitted_unprivileged_params.
  #
  def self.permitted_params
    self.permitted_unprivileged_params() + [
      :admin,
      :designer,
      :notes
    ]
  end

  def has_role?(role)
    respond_to?("#{role}?") && send("#{role}?")
  end

  def sha1(phrase)
    Digest::SHA1.hexdigest("--#{salt}--#{phrase}--")
  end

  def self.authenticate(login_or_email, password)
    user = self.where('login = ? OR email = ?', login_or_email, login_or_email).first
    user if user && user.authenticated?(password)
  end

  def authenticated?(password)
    self.password == sha1(password)
  end

  def after_initialize
    @confirm_password = true
  end

  def confirm_password?
    @confirm_password
  end

  def remember_me
    unless self.session_token?
      self.update_column(
        :session_token,
        sha1(Time.now + Radiant::Configuration['session_timeout'].to_i)
      )
    end
  end

  def forget_me
    self.update_column(:session_token, nil)
  end

  private

    def validate_length_of_password?
      new_record? or not password.to_s.empty?
    end

    before_create :encrypt_password
    def encrypt_password
      self.salt = Digest::SHA1.hexdigest("--#{Time.now}--#{login}--sweet harmonious biscuits--")
      self.password = sha1(password)
    end

    before_update :encrypt_password_unless_empty_or_unchanged
    def encrypt_password_unless_empty_or_unchanged
      user = self.class.find(self.id)
      case password
      when ''
        self.password = user.password
      when user.password
      else
        encrypt_password
      end
    end

end
