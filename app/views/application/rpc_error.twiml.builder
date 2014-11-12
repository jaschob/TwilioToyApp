xml.instruct!
xml.Response do |xml|
  if twilio_sms_type?
    xml.Message "Bitcoin error: #{error}"
  elsif twilio_voice_type?
    xml.Say "We're sorry, a bitcoin error occurred: #{error}."
  end
end

