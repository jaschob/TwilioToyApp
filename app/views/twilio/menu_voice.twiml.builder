xml.instruct!
xml.Response do |xml|
  xml.Say "Hello #{current_user.username}"
  xml.Gather :numDigits => '1',
             :action => twilio_path("dispatch_voice", format: :xml),
             :method => 'post' do |xml|
    xml.Say "Press 1 to hear your current balance."
  end
  xml.Say "I'm sorry, you didn't make a selection. Good bye."
  xml.Hangup
end
