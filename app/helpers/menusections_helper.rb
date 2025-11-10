module MenusectionsHelper
  # Format time range with proper zero-padding and icons
  # Example: 09:30 - 17:00
  def format_time_range(from_hour, from_min, to_hour, to_min)
    from_time = format_time(from_hour, from_min)
    to_time = format_time(to_hour, to_min)
    
    content_tag(:span, class: 'time-range d-inline-flex align-items-center gap-1') do
      concat content_tag(:i, '', class: 'bi bi-clock', title: 'Start time')
      concat content_tag(:span, from_time)
      concat content_tag(:span, '–', class: 'mx-1') # En dash
      concat content_tag(:i, '', class: 'bi bi-clock-fill', title: 'End time')
      concat content_tag(:span, to_time)
    end
  end
  
  private
  
  # Format individual time with zero-padding
  # Example: 9, 5 => "09:05"
  def format_time(hour, min)
    "%02d:%02d" % [hour, min]
  end
end
