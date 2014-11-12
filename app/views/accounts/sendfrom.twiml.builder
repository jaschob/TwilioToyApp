xml.instruct!
xml.Response do |xml|
  xml.Message "A transfer of #{amount.to_s('F')} to #{recipient.username}  was successfully posted to the bitcoin network."
end
