import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"
import { Modal } from "bootstrap"

export default class extends Controller {
  static targets = [
    "confirmModal", "editItemModal", "editItemForm", "editItemId",
    "editItemName", "editItemDescription", "editItemPrice",
    "editItemSection", "editItemPosition",
    "editItemAllergens", "editItemVegetarian", "editItemVegan",
    "editItemGlutenFree", "editItemDairyFree", "editItemNutFree"
  ]

  connect() {
    // Initialize modals
    if (this.hasConfirmModalTarget) {
      this.confirmModal = new Modal(this.confirmModalTarget)
    }
    
    if (this.hasEditItemModalTarget) {
      this.editItemModal = new Modal(this.editItemModalTarget)
    }
    
    // Add event listener for keyboard shortcuts
    document.addEventListener('keydown', this.handleKeyDown.bind(this))
  }
  
  disconnect() {
    // Clean up event listeners
    document.removeEventListener('keydown', this.handleKeyDown.bind(this))
  }
  
  handleKeyDown(event) {
    // Close modals with Escape key
    if (event.key === 'Escape') {
      if (this.hasConfirmModalTarget && !this.confirmModalTarget.classList.contains('hidden')) {
        this.hideConfirmModal()
      }
      if (this.hasEditItemModalTarget && !this.editItemModalTarget.classList.contains('hidden')) {
        this.hideEditItemModal()
      }
    }
  }
  
  // Confirmation Modal Methods
  showConfirmModal() {
    if (this.hasConfirmModalTarget) {
      this.confirmModal.show()
    }
  }
  
  hideConfirmModal() {
    if (this.hasConfirmModalTarget) {
      this.confirmModal.hide()
    }
  }
  
  submitForm() {
    // This will be called when the user confirms the import
    // The form submission is handled by Rails via the button_to helper
    // This method is just a placeholder for any additional client-side logic
  }
  
  // Edit Item Modal Methods
  showEditItemModal(event) {
    if (!this.hasEditItemModalTarget) return
    
    const itemId = event.currentTarget.dataset.itemId
    const itemName = event.currentTarget.dataset.itemName || ''
    const itemDescription = event.currentTarget.dataset.itemDescription || ''
    const itemPrice = event.currentTarget.dataset.itemPrice || ''
    const itemSection = event.currentTarget.dataset.itemSection || ''
    const itemPosition = event.currentTarget.dataset.itemPosition || ''
    
    // Parse allergens and dietary restrictions from data attributes
    let allergens = []
    try {
      allergens = JSON.parse(event.currentTarget.dataset.itemAllergens || '[]')
    } catch (e) {
      console.error('Error parsing allergens:', e)
    }
    
    let dietaryRestrictions = []
    try {
      dietaryRestrictions = JSON.parse(event.currentTarget.dataset.itemDietaryRestrictions || '[]')
    } catch (e) {
      console.error('Error parsing dietary restrictions:', e)
    }
    
    // Set form values
    this.editItemIdTarget.value = itemId
    this.editItemNameTarget.value = itemName
    this.editItemDescriptionTarget.value = itemDescription
    this.editItemPriceTarget.value = itemPrice
    if (this.hasEditItemSectionTarget) this.editItemSectionTarget.value = itemSection
    if (this.hasEditItemPositionTarget) this.editItemPositionTarget.value = itemPosition
    
    // Set allergens (TomSelect if present, fallback to native/jQuery)
    if (this.hasEditItemAllergensTarget) {
      const el = this.editItemAllergensTarget
      if (el.tomselect) {
        try {
          el.tomselect.setValue(allergens, true)
        } catch (e) {
          console.warn('TomSelect setValue failed, falling back:', e)
          el.value = ''
        }
      } else if (window.$) {
        try { $(el).val(allergens).trigger('change') } catch (_) {}
      } else {
        // native multi-select
        Array.from(el.options).forEach(opt => opt.selected = allergens.includes(opt.value))
      }
    }
    
    // Set dietary restrictions checkboxes
    this.setDietaryRestrictionCheckbox('vegetarian', dietaryRestrictions)
    this.setDietaryRestrictionCheckbox('vegan', dietaryRestrictions)
    this.setDietaryRestrictionCheckbox('gluten_free', dietaryRestrictions)
    this.setDietaryRestrictionCheckbox('dairy_free', dietaryRestrictions)
    this.setDietaryRestrictionCheckbox('nut_free', dietaryRestrictions)
    
    // Show the modal
    this.editItemModal.show()
  }
  
  setDietaryRestrictionCheckbox(type, restrictions) {
    const hasTargetProp = this[`hasEditItem${this.capitalize(type)}Target`]
    if (hasTargetProp) {
      const target = this[`editItem${this.capitalize(type)}Target`]
      if (target) target.checked = restrictions.includes(type)
    }
  }
  
  hideEditItemModal() {
    if (this.hasEditItemModalTarget) {
      this.editItemModal.hide()
    }
  }
  
  saveItem(event) {
    if (!this.hasEditItemFormTarget) return
    
    const form = this.editItemFormTarget
    const formData = new FormData(form)
    const itemId = formData.get('item_id')
    
    // Get selected allergens (handled by Select2)
    const allergens = $(this.editItemAllergensTarget).val() || []
    
    // Get selected dietary restrictions from checkboxes
    const dietaryRestrictions = []
    if (this.editItemVegetarianTarget.checked) dietaryRestrictions.push('vegetarian')
    if (this.editItemVeganTarget.checked) dietaryRestrictions.push('vegan')
    if (this.editItemGlutenFreeTarget.checked) dietaryRestrictions.push('gluten_free')
    if (this.editItemDairyFreeTarget.checked) dietaryRestrictions.push('dairy_free')
    if (this.editItemNutFreeTarget.checked) dietaryRestrictions.push('nut_free')
    
    // Add allergens and dietary_restrictions to form data
    formData.set('allergens', JSON.stringify(allergens))
    formData.set('dietary_restrictions', JSON.stringify(dietaryRestrictions))
    
    // Submit the form via fetch
    fetch(`/ocr_menu_items/${itemId}`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector("[name='csrf-token']").content,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        ocr_menu_item: {
          name: formData.get('item_name'),
          description: formData.get('item_description'),
          price: parseFloat(formData.get('item_price')) || 0,
          allergens: allergens,
          dietary_restrictions: dietaryRestrictions
        }
      }),
      credentials: 'same-origin'
    })
    .then(response => {
      if (!response.ok) throw new Error('Network response was not ok')
      return response.json()
    })
    .then(data => {
      // Close the modal
      this.hideEditItemModal()
      
      // Reload the page to show updated data
      // In a real app, you might want to update the DOM directly instead
      window.location.reload()
    })
    .catch(error => {
      console.error('Error updating menu item:', error)
      alert('There was an error updating the menu item. Please try again.')
    })
  }
  
  // Helper method to capitalize first letter
  capitalize(string) {
    return string.charAt(0).toUpperCase() + string.slice(1)
  }
  
  // Toggle section items visibility
  toggleSection(event) {
    const sectionId = event.currentTarget.dataset.sectionId
    const itemsContainer = document.querySelector(`[data-section-id="${sectionId}"]`)
    if (itemsContainer) {
      itemsContainer.classList.toggle('hidden')
    }
  }
}
