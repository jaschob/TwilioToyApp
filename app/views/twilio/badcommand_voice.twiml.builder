xml.instruct!
xml.Response do |xml|
  xml.Say "#{command} was not a valid choice. Good bye."
  xml.Hangup
end
