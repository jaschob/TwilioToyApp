class User < ActiveRecord::Base
  NOTIFY_NEVER = "never"
  NOTIFY_SMS   = "SMS"
  NOTIFY_VOICE = "Voice"

  # uses authlogic gem for logins
  acts_as_authentic

  # validation set up
  validates :username, presence: true, uniqueness: true
  validates :phone, presence: false, format: {
    with: /\A (\+1 \d{10})? \z/x,  # only allowing USA
    message: "must be a +1 10 digit number"
  }
  validates :notify_tx, inclusion: {
    in: %w( never SMS Voice),
    message: "%{value} not one of SMS, Voice or never"
  }
  validate :username_cannot_change, :on => :update

  # ActiveRecord callbacks for lifecycle events
  before_validation :normalize_phone

  # bitcoin related methods - will make RPC call to bitcoind server
  # returns a (non-persisted) account object that can interface with the
  # bitcoind client via RPC
  def coin_account
    @coin_account if @coin_account
    @coin_account = Coin::Account.new(username)
  end

  # helpers and convenience methods

  # see if the user can interact with Twilio
  def can_do_twilio?
    not phone.blank?
  end

  def notify_never?
    notify_tx == NOTIFY_NEVER
  end

  def notify_by_sms?
    notify_tx == NOTIFY_SMS
  end

  def notify_by_voice?
    notify_tx == NOTIFY_VOICE
  end

  protected

  # be a little lenient with user phone number entry!
  def normalize_phone
    md = /\A
            (?:[+]\s*1)?
            [^0-9]* (\d{3})
            [^0-9]* (\d{3})
            [^0-9]* (\d{4})
            [^0-9]*
          \z/x.match(phone)
    if md
      self.phone = "+1" + md[1] + md[2] + md[3]
    end
  end

  private

  # validation method to ensure the username isn't changed after
  # creation
  def username_cannot_change
    if username_changed?
      errors.add :username, "may not be modified after creation"
    end
  end
end
