// OCR and document processing functionality
import '../ocr_menu_imports.js'

// Only load pako when compression is needed
if (document.querySelector('[data-ocr-import]') || document.querySelector('[data-pdf-processing]')) {
  import('pako').then((pako) => {
    window.pako = pako
    console.log('[SmartMenu] Pako compression loaded for OCR')
  }).catch(error => {
    console.warn('[SmartMenu] Pako not available:', error.message)
  })
}

console.log('[SmartMenu] OCR bundle loaded')