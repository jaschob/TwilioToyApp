module TransactionsHelper
  def html_for_tx_date(tx)
    tx.time.localtime.strftime("%m/%d %H:%M %Z")
  end

  def html_for_tx_category(tx)
    case
      when tx.category == "receive" then "Received"
      when tx.category == "send" then "Sent"
      when tx.category == "immature" then "Mined (immature)"
      when tx.category == "generate" then "Mined"
      when tx.category == "orphan" then "Orphaned Mined Block"
      else tx.category
    end
  end

  def html_for_tx_amount(tx)
    html = amount_for_display tx.amount
    if tx.fee and not tx.fee.zero?
      html += " (#{amount_for_display tx.fee} fee)"
    end
    html
  end

  def html_for_tx_id(tx)
    html = "<span title=\"#{tx.txid}\">"
    html += link_to(shorten_hash(tx.txid, 10),
                    "https://www.biteasy.com/testnet/transactions/#{tx.txid}",
                    { target: "_blank" })
    html += "</span>"
  end

  def html_for_tx_confirmations(tx)
    tx.confirmations && tx.confirmations > 0 ?
      tx.confirmations.to_s
      : link_to("Unconfirmed", "https://en.bitcoin.it/wiki/Confirmation",
        { target: "_blank" })
  end

  def html_for_tx_blockhash(tx)
    if tx.blockhash
      html = "<span title=\"#{tx.blockhash}\">"
      html += link_to(shorten_hash(tx.blockhash, 10, at_beginning: true),
                      "https://www.biteasy.com/testnet/blocks/#{tx.blockhash}",
                      { target: "_blank" })
      html += "</span>"
    else
      "N/A"
    end
  end
end
