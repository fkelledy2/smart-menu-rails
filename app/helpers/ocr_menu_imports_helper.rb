module OcrMenuImportsHelper
  # Returns the appropriate Tailwind classes for a status badge
  def status_badge_classes(status)
    base_classes = 'px-2.5 py-0.5 rounded-full text-xs font-medium inline-flex items-center'
    
    case status.to_sym
    when :pending, :uploaded
      base_classes + ' bg-yellow-100 text-yellow-800'
    when :processing
      base_classes + ' bg-blue-100 text-blue-800 animate-pulse'
    when :completed
      base_classes + ' bg-green-100 text-green-800'
    when :failed
      base_classes + ' bg-red-100 text-red-800'
    else
      base_classes + ' bg-gray-100 text-gray-800'
    end
  end
  
  # Returns a badge for the status
  def status_badge(status)
    content_tag(:span, status.titleize, class: status_badge_classes(status))
  end
  
  # Returns a progress bar for the import
  def import_progress_bar(import)
    return unless import.processing?
    
    content_tag(:div, class: 'w-full bg-gray-200 rounded-full h-2.5 mt-2') do
      content_tag(:div, 
                 '', 
                 class: 'bg-blue-600 h-2.5 rounded-full', 
                 style: "width: #{import.progress || 0}%")
    end
  end
  
  # Returns a human-readable file size
  def human_file_size(bytes)
    return '0 B' if bytes.blank? || bytes.zero?
    
    units = %w[B KB MB GB TB]
    exp = (Math.log(bytes) / Math.log(1024)).to_i
    exp = units.size - 1 if exp > units.size - 1
    
    number_to_human_size(bytes, precision: 2, significant: true)
  end
end
