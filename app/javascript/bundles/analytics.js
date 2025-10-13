// Analytics and reporting functionality
import '../metrics.js'

// Only load DateTime when date functionality is needed
if (document.querySelector('[data-datetime]') || document.querySelector('[data-chart]')) {
  import('luxon').then(({ DateTime }) => {
    window.DateTime = DateTime
    console.log('[SmartMenu] DateTime loaded for analytics')
  }).catch(error => {
    console.warn('[SmartMenu] DateTime not available, using native Date:', error.message)
  })
}

console.log('[SmartMenu] Analytics bundle loaded')