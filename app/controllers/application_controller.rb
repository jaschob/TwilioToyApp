class ApplicationController < ActionController::Base
  TRUE_WORDS = %w( true yes )

  include TwilioHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  protect_from_forgery with: :null_session # twilio posts directly

  # any error from the bitcoin RPC call should be nicely shown
  rescue_from Coin::RPC::RPCError do |exception|
    error_text = "Bitcoin client error: #{exception.message}"
    respond_to do |format|
      format.json { render json: error_text,
                           status: :unprocessable_entity
      }
      format.xml {
        render "rpc_error_#{twilio_type}.twiml",
                :locals => { :error => error_text } if twilio_type
      }
      format.html { flash[:error]  = error_text }
    end
  end

  helper_method :current_user, :require_user

  # Shows information about the app, most importantly the hash of the current
  # best block and the time of the last activity in any account.
  def poll
    @best_block = Coin::Account.best_block
    @activity = Coin::Account.last_activity
  end

  protected

  def with_html?
    TRUE_WORDS.include? params[:with_html]
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    # for the normal case, use the user_session to identify the user
    @current_user = current_user_session &&
      current_user_session.record || current_twilio_user
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end


  def current_twilio_user
    if from_twilio? && params[:From]
      @current_user = User.find_by(phone: params[:From])
    end
  end

  def require_user
    unless current_user
      respond_to do |format|
        format.html {
          flash[:notice] = "Please log in."
          redirect_to login_url
        }
        format.xml {
          if from_twilio?
            render "unknown_#{twilio_type}.twiml"
          else
            redirect_to login_url
          end
        }
      end
      return false
    end
  end
end
