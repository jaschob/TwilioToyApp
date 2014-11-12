xml.instruct!
xml.Response do |xml|
  xml.Say "The current mining difficulty is #{@info['difficulty']}."
  xml.Redirect twilio_voice_path("menu_network", format: :twiml)
end
