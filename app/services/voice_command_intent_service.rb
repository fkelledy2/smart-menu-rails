class VoiceCommandIntentService
  def initialize(transcript:)
    @transcript = transcript.to_s.strip
  end

  def parse
    t = strip_politeness(@transcript).downcase

    return { type: 'empty', raw: @transcript } if t.blank?

    if t.match?(/\b(start|open|begin|new)\b.*\b(order|tab)\b|\b(start|open)\s+(an\s+)?order\b|\bcan\s+i\s+start\b.*\b(order|tab)\b/)
      return { type: 'start_order', raw: @transcript }
    end

    if t.match?(/\b(close|end|finish|complete|cancel|stop)\b.*\b(order|tab)\b|\b(close|end)\s+(the\s+)?order\b|\bwe'?re\s+done\b/)
      return { type: 'close_order', raw: @transcript }
    end

    if t.match?(/\b(request|get|bring|can\s+i\s+have|may\s+i\s+have)\b.*\b(bill|check|receipt)\b|\b(bill|check|receipt)\b.*\bplease\b|\bready\s+to\s+pay\b/)
      return { type: 'request_bill', raw: @transcript }
    end

    if t.match?(/\b(submit|place|confirm|send|complete|finali[sz]e)\b.*\b(order)\b|\bcheckout\b|\bthat'?s\s+all\b|\bwe'?re\s+ready\b/)
      return { type: 'submit_order', raw: @transcript }
    end

    if (m = t.match(/\b(remove|delete|take\s+off|take\s+out|cancel|drop|undo|scratch)\b\s+(?<qty>\d+|one|two|three)?\s*(?<name>.+)$/))
      return {
        type: 'remove_item',
        raw: @transcript,
        qty: normalize_qty(m[:qty]),
        query: strip_politeness(m[:name].to_s),
      }
    end

    if (m = t.match(/\b(add|order|get|give\s+me|i\s+want|i'?d\s+like|can\s+i\s+get|can\s+i\s+have|we'?ll\s+have|make\s+it)\b\s+(?<qty>\d+|one|two|three)?\s*(?<name>.+)$/))
      return {
        type: 'add_item',
        raw: @transcript,
        qty: normalize_qty(m[:qty]),
        query: strip_politeness(m[:name].to_s),
      }
    end

    { type: 'unknown', raw: @transcript }
  end

  private

  def strip_politeness(text)
    s = text.to_s.strip.downcase

    # Remove trailing punctuation/noise first
    s = s.gsub(/[\s\.,!\?]+\z/, '')

    # Remove common trailing politeness/filler phrases (repeat until stable)
    loop do
      before = s
      s = s.gsub(/(?:\s*(?:please|pls|plz|thanks|thank\s+you|thank\s+u|thx|cheers|ta|much\s+appreciated|appreciate\s+it))\s*\z/, '')
      s = s.gsub(/[\s\.,!\?]+\z/, '')
      break if s == before
    end

    s.strip
  end

  def normalize_qty(q)
    return 1 if q.blank?
    s = q.to_s.strip
    return s.to_i if s.match?(/^\d+$/)
    return 1 if s == 'one'
    return 2 if s == 'two'
    return 3 if s == 'three'
    1
  end
end
