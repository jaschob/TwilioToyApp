module ApplicationHelper
  CUTOFF_FOR_BTC = BigDecimal.new("0.00001000")
  PHONE_REGEX = /\A [+]1(\d{3})(\d{3})(\d{4}) \z/x

  YADA = "..."

  # format a bitcoin amount for display
  def amount_for_display(amt)
    if amt.abs < CUTOFF_FOR_BTC and not amt.zero?
      satoshi = amt * BigDecimal.new("100000000")
      "#{satoshi.truncate} " +
        link_to("Satoshi",
                "https://en.bitcoin.it/wiki/Satoshi",
                :target => '_blank')
    else
      "#{amt.to_s('F')} BTC"
    end
  end

  def shorten_hash(text, cutoff = 10, opts = {})
    case
      when text.blank?, text.size <= cutoff then text

      # if we can fit a ... in the middle and one char, do that
      when YADA.size + 1 <= cutoff
        case
          when opts[:at_end]
            text[0, cutoff - YADA.size] + YADA
          when opts[:at_beginning]
            YADA + text[text.size - cutoff + YADA.size, text.size]
        
          else
            midpoint = (text.size / 2).to_i
            cutoff_start = ((cutoff - YADA.size) / 2).to_i
            cutoff_end = text.size - cutoff + cutoff_start + YADA.size
            text[0, cutoff_start] + YADA +
            text[cutoff_end, text.size]
        end

      # that's a short cutoff!
      else
        text[0, cutoff]
    end

    #cutoff = 7 if cutoff < 7    # for this to make any sense!
    #if text.size > cutoff
    #  text[0, 3] + "..." + text[-cutoff + 3, text.size]
    #else
    #  text
    #end
  end

  # turn the internal phone number into something nicely readable
  def phone_for_display(phone)
    if phone.blank? then return "N/A" end
    md = PHONE_REGEX.match(phone)
    if md
      "+1 (#{md[1]}) #{md[2]}-#{md[3]}"
    else
      phone
    end
  end
end
