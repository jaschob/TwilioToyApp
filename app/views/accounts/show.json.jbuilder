json.name @account.name

if html
  json.balance do |json|
    balance = @account.balance  
    json.raw balance
    json.html amount_for_display balance
  end
else
  json.balance @account.balance
end
