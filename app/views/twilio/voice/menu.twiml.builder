xml.instruct!
xml.Response do |xml|
  
  if @bad_digit
    xml.Say @bad_digit + " is not a valid selection."
  else
    xml.Say "Hello #{current_user.username}"
  end

  xml.Gather :numDigits => '1' do |xml|
    xml.Say "Press 1 for Bitcoin network information."
    xml.Say "Press 2 to hear your current balance."
    xml.Say "To end this call, hang up or press 0."
  end

  xml.Say "I'm sorry, you didn't make a selection. Please try again."
end
