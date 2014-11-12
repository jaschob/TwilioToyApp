xml.instruct!
xml.Response do |xml|
  xml.Say "The current network hashrate is #{@info['networkhashps']} hashes per second."
  xml.Redirect twilio_voice_path("menu_network", format: :twiml)
end
