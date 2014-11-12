xml.instruct!
xml.Response do |xml|
  if @bad_digit
    xml.Say @bad_digit + " is not a valid selection."
  end

  xml.Gather :numDigits => '1' do |xml|
    xml.Say "For the current block chain height, press 1."
    xml.Say "For the current mining difficulty, press 2."
    xml.Say "For the current network hashrate, press 3."
    xml.Say "To return to the main menu, press 4."
  end

  xml.Say "I'm sorry, you didn't select an option."
end
