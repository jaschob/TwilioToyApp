json.array!(@users) do |user|
  balance = user.coin_account.balance(@known_balances)
  
  json.extract! user, :id, :username
  if with_html?
    json.balance do |json|    
      json.raw balance
      json.html amount_for_display(balance)
    end
  else
    json.balance balance
  end
end
