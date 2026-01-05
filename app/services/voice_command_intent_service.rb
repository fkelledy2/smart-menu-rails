class VoiceCommandIntentService
  def initialize(transcript:, locale: nil)
    @transcript = transcript.to_s.strip
    @locale = normalize_locale(locale)
  end

  def parse
    t = strip_politeness(@transcript, @locale).downcase

    return { type: 'empty', raw: @transcript } if t.blank?

    if t.match?(start_order_regex(@locale))
      return { type: 'start_order', raw: @transcript }
    end

    if t.match?(close_order_regex(@locale))
      return { type: 'close_order', raw: @transcript }
    end

    if t.match?(request_bill_regex(@locale))
      return { type: 'request_bill', raw: @transcript }
    end

    if t.match?(submit_order_regex(@locale))
      return { type: 'submit_order', raw: @transcript }
    end

    if (m = t.match(remove_item_regex(@locale)))
      return {
        type: 'remove_item',
        raw: @transcript,
        qty: normalize_qty(m[:qty]),
        query: strip_politeness(m[:name].to_s, @locale),
      }
    end

    if (m = t.match(add_item_regex(@locale)))
      return {
        type: 'add_item',
        raw: @transcript,
        qty: normalize_qty(m[:qty]),
        query: strip_politeness(m[:name].to_s, @locale),
      }
    end

    { type: 'unknown', raw: @transcript }
  end

  private

  def normalize_locale(locale)
    s = locale.to_s.strip
    s = s.split(/[-_]/).first.to_s.downcase
    s.presence || 'en'
  end

  def strip_politeness(text, locale)
    s = text.to_s.strip.downcase

    # Remove trailing punctuation/noise first
    s = s.gsub(/[\s\.,!\?]+\z/, '')

    politeness = politeness_words(locale)

    # Remove common trailing politeness/filler phrases (repeat until stable)
    loop do
      before = s
      s = s.gsub(/(?:\s*(?:#{politeness}))\s*\z/, '')
      s = s.gsub(/[\s\.,!\?]+\z/, '')
      break if s == before
    end

    s.strip
  end

  def politeness_words(locale)
    base = %w[pls plz thanks thx cheers ta]
    case locale
    when 'fr'
      (base + ['s\s*il\s+vous\s+pla[iî]t', 'merci', 'stp', 'svp']).join('|')
    when 'it'
      (base + ['per\s+favore', 'grazie']).join('|')
    when 'es'
      (base + ['por\s+favor', 'gracias']).join('|')
    else
      (base + ['please', 'thank\s+you', 'thank\s+u', 'much\s+appreciated', 'appreciate\s+it']).join('|')
    end
  end

  def start_order_regex(locale)
    case locale
    when 'fr'
      /\b(ouvrir|commencer|d[ée]marrer|lancer|cr[ée]er)\b.*\b(commande|addition|note|table)\b|\b(commencer|ouvrir)\s+(une\s+)?commande\b/
    when 'it'
      /\b(inizia|apr[ií]|aprire|comincia|avvia)\b.*\b(ordine|conto|tab)\b|\bposso\s+iniziare\b.*\b(ordine|conto)\b/
    when 'es'
      /\b(abrir|empezar|comenzar|iniciar|crear)\b.*\b(pedido|cuenta|mesa)\b|\b(quiero\s+empezar|podemos\s+empezar)\b.*\b(pedido|cuenta)\b/
    else
      /\b(start|open|begin|new)\b.*\b(order|tab)\b|\b(start|open)\s+(an\s+)?order\b|\bcan\s+i\s+start\b.*\b(order|tab)\b/
    end
  end

  def close_order_regex(locale)
    case locale
    when 'fr'
      /\b(fermer|terminer|finir|cl[ôo]turer|annuler|stopper)\b.*\b(commande|addition|note)\b|\bon\s+a\s+fini\b/
    when 'it'
      /\b(chiudi|termina|finisci|annulla|stop)\b.*\b(ordine|conto)\b|\babbiamo\s+finito\b/
    when 'es'
      /\b(cerrar|terminar|finalizar|acabar|cancelar|parar)\b.*\b(pedido|cuenta)\b|\bya\s+terminamos\b/
    else
      /\b(close|end|finish|complete|cancel|stop)\b.*\b(order|tab)\b|\b(close|end)\s+(the\s+)?order\b|\bwe'?re\s+done\b/
    end
  end

  def request_bill_regex(locale)
    case locale
    when 'fr'
      /\b(addition|note|facture)\b|\b(est[-\s]*ce\s+que\s+je\s+peux\s+avoir)\b.*\b(addition|note)\b|\b(apporter|donner)\b.*\b(addition|note)\b/
    when 'it'
      /\b(conto|scontrino|ricevuta)\b|\b(posso\s+avere)\b.*\b(conto|scontrino|ricevuta)\b|\b(porta|porta\s+il)\b.*\b(conto)\b/
    when 'es'
      /\b(cuenta|factura|recibo)\b|\b(puedo\s+tener)\b.*\b(cuenta|factura|recibo)\b|\b(trae|traer)\b.*\b(cuenta)\b/
    else
      /\b(request|get|bring|can\s+i\s+have|may\s+i\s+have)\b.*\b(bill|check|receipt)\b|\b(bill|check|receipt)\b.*\bplease\b|\bready\s+to\s+pay\b/
    end
  end

  def submit_order_regex(locale)
    case locale
    when 'fr'
      /\b(valider|envoyer|confirmer|passer)\b.*\b(commande)\b|\b(c'?est\s+tout|on\s+est\s+pr[êe]t)\b/
    when 'it'
      /\b(invia|conferma|manda|completa|finalizza)\b.*\b(ordine)\b|\b(abbiamo\s+finito|siamo\s+pronti)\b/
    when 'es'
      /\b(enviar|confirmar|hacer|realizar|finalizar|completar)\b.*\b(pedido)\b|\b(eso\s+es\s+todo|estamos\s+listos)\b/
    else
      /\b(submit|place|confirm|send|complete|finali[sz]e)\b.*\b(order)\b|\bcheckout\b|\bthat'?s\s+all\b|\bwe'?re\s+ready\b/
    end
  end

  def remove_item_regex(locale)
    case locale
    when 'fr'
      /\b(retire|enl[èe]ve|supprime|annule)\b\s+(?<qty>\d+|un|une|deux|trois)?\s*(?<name>.+)$/
    when 'it'
      /\b(togli|rimuovi|cancella|annulla)\b\s+(?<qty>\d+|uno|una|due|tre)?\s*(?<name>.+)$/
    when 'es'
      /\b(quita|elimina|borra|cancela)\b\s+(?<qty>\d+|uno|una|dos|tres)?\s*(?<name>.+)$/
    else
      /\b(remove|delete|take\s+off|take\s+out|cancel|drop|undo|scratch)\b\s+(?<qty>\d+|one|two|three)?\s*(?<name>.+)$/
    end
  end

  def add_item_regex(locale)
    case locale
    when 'fr'
      /\b(ajoute|commander|je\s+veux|j'?aimerais|je\s+prends|on\s+prend|peux\s+tu\s+ajouter)\b\s+(?<qty>\d+|un|une|deux|trois)?\s*(?<name>.+)$/
    when 'it'
      /\b(aggiungi|ordina|vorrei|voglio|prendo|posso\s+avere|ci\s+prendiamo)\b\s+(?<qty>\d+|uno|una|due|tre)?\s*(?<name>.+)$/
    when 'es'
      /\b(agrega|a[ñn]ade|añade|pedir|quiero|me\s+gustar[ií]a|ponme|dame|podemos\s+tener)\b\s+(?<qty>\d+|uno|una|dos|tres)?\s*(?<name>.+)$/
    else
      /\b(add|order|get|give\s+me|i\s+want|i'?d\s+like|can\s+i\s+get|can\s+i\s+have|we'?ll\s+have|make\s+it)\b\s+(?<qty>\d+|one|two|three)?\s*(?<name>.+)$/
    end
  end

  def normalize_qty(q)
    return 1 if q.blank?
    s = q.to_s.strip
    return s.to_i if s.match?(/^\d+$/)
    return 1 if %w[one un une uno una].include?(s)
    return 2 if %w[two deux due dos].include?(s)
    return 3 if %w[three trois tre tres].include?(s)
    1
  end
end
