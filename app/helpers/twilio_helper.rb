module TwilioHelper
  SMS = "sms"
  VOICE = "voice"

  # TODO (need SSL to try this out)
  # https://www.twilio.com/docs/security
  def from_twilio?
    return @from_twilio if defined?(@from_twilio)

    #raw_params = request.post? ? request.request_parameters :
    #  request.query_parameters
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

    if twilio_type then
      @from_twilio = true         # gaping security hole!
    else
      @from_twilio = false
    end
  end

  def twilio_type
    return @twilio_type if defined?(@twilio_type)

    case
    when params.has_key?(:SmsSid) then @twilio_type = SMS
    when params.has_key?(:CallSid) then @twilio_type = VOICE
    else @twilio_type = nil
    end

  end

  def twilio_sms_type?
    twilio_type == SMS
  end

  def twilio_voice_type?
    twilio_type == VOICE
  end
end
