class ApplicationController < ActionController::Base

  include TwilioHelper
  include TwilioAuthHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  protect_from_forgery with: :null_session # twilio posts directly

  # make this method available to views, too
  helper_method :current_user

  ####################################################################
  ## General application error handling

  # this is a defined error from the bitcoin client
  rescue_from Coin::RPC::RPCError do |exception|
    error_text = "Bitcoin client error: #{exception.message}"
    respond_to do |format|
      format.html { flash[:error]  = error_text }
      format.json { render json: error_text,
                           status: :unprocessable_entity
      }
      format.twiml {
        render "rpc_error",
                status: :unprocessable_entity,
                :locals => { :error => error_text }
      }
    end
  end

  # This is more serious: the bitcoind client process isn't reachable.
  rescue_from Coin::RPC::RPCConnectionError do |exception|
    Rails.logger.info "ASDASDA"
    respond_to do |format|
      format.html { render file: "/public/bitcoind_down.html", layout: false }
      format.json { render json: exception,
                           status: :internal_server_error }
      format.twiml { head status: :internal_server_error }
    end
  end

  # Shows information about the app, most importantly the hash of the current
  # best block and the time of the last activity in any account.
  def poll
    @best_block = Coin::Account.best_block
    @activity = Coin::Account.last_activity
  end

  private

  ####################################################################
  ### authentication (see TwilioAuthHelper for Twilio functionality)
  def require_user
    unless current_user
      respond_to do |format|
        format.html {
          flash[:notice] = "Please log in."
          redirect_to login_url
        }
        format.twiml {
          if twilio_voice_type? # use reject verb for calls
            render "reject.twiml"
          elsif twilio_sms_type? # just give back a 200 for messages
            head status: :ok
          else                  # shouldn't happen
            head status: :unauthorized
          end
        }

        # fallback: 401 unauthorized
        format.all { head status: :unauthorized }
      end
    end
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = current_user_session &&
      current_user_session.record
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find ||
      new_twilio_user_session
  end
end
