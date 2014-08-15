xml.instruct!
xml.Response do |xml|
  xml.Say "Your current balance is #{@account.balance.to_s('F')}."
end
