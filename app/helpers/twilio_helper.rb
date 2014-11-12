module TwilioHelper
  SMS = "sms"
  VOICE = "voice"

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
