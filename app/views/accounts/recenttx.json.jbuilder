json.array! @recent_tx do |tx|
  with_html? ? json.id do |json|
    json.raw tx.txid
    json.html html_for_tx_id(tx)
  end : json.id(tx.txid)
  with_html? ? json.category do |json|
    json.raw tx.category
    json.html html_for_tx_category(tx)
  end : json.category(tx.category)
  with_html? ? json.date do |json|
    json.raw tx.time
    json.html html_for_tx_date(tx)
  end : json.time(tx.time)
  with_html? ? json.amount do |json|
    json.raw tx.amount
    json.html html_for_tx_amount(tx)
  end : json.amount(tx.amount)
  with_html? ? json.confirmations do |json|
    json.raw tx.confirmations
    json.html html_for_tx_confirmations(tx)
  end : json.confirmations(tx.confirmations)
  with_html? ? json.blockhash do |json|
    json.raw tx.blockhash
    json.html html_for_tx_blockhash(tx)
  end : json.blockhash(tx.blockhash)
end