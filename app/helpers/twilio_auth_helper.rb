module TwilioAuthHelper
  # Finds the User record from phone number Twilio provides in its requests, and
  # creates a new UserSession for it.
  def new_twilio_user_session
    # validate signature provided via X-Twilio-Signature
    if Rails.application.enforce_twilio_auth? &&
        ! from_twilio?
      return nil
    end

    # identify the user by their phone number
    phone_number = params[:From]
    user = ! phone_number.blank? && User.find_by_phone(phone_number)
    user && UserSession.create(user, false)
  end

  private

  # Validates that the request was signed by our auth token.
  # See https://www.twilio.com/docs/security
  def from_twilio?
    return @from_twilio if defined?(@from_twilio)

    sent_sig = headers['X-Twilio-Signature']
    validator = Twilio::Util::RequestValidator.new(
      Rails.application.twilio_auth_token)

    sig = validator.build_signature_for(request.original_url,
                                        request.post? &&
                                          request.request_parameters ||
                                        [])

    Rails.logger.info "Twilio-Sig was: #{sent_sig}; we calculated " +
      "#{sig} from URL #{request.original_url} and params " +
      "#{request.post? && request.request_parameters || []}."

    return sent_sig == sig
  end
end
