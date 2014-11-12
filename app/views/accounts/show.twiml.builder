xml.instruct!
xml.Response do |xml|
  case

  when twilio_voice_type?
    xml.Say "Your current balance is #{@account.balance.to_s('F')}."
    xml.Redirect twilio_voice_path format: :twiml

  when twilio_sms_type?
    xml.Message "Your current balance is #{amount_for_display(@account.balance, no_html: true)}."

  end
end

