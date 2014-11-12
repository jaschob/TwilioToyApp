xml.instruct!
xml.Response do |xml|
  xml.Say "The block chain height is #{@info['blocks']}."
  xml.Redirect twilio_voice_path("menu_network", format: :twiml)
end
