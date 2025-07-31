// Utility function to initialize an accessible modal
export function initAccessibleModal(modalElement) {
    if (!modalElement || modalElement._modalInstance) return null;
    
    // Add data-modal-visible attribute if it doesn't exist
    if (!modalElement.hasAttribute('data-modal-visible')) {
        modalElement.setAttribute('data-modal-visible', 'false');
    }

    // Initialize the modal
    const modalInstance = new bootstrap.Modal(modalElement, {
        backdrop: true,
        keyboard: true,
        focus: false // We'll handle focus manually
    });
    
    // Store the instance on the element
    modalElement._modalInstance = modalInstance;
    
    // Prevent Bootstrap from managing aria-hidden
    const originalSetAttribute = modalElement.setAttribute;
    modalElement.setAttribute = function(name, value) {
        if (name === 'aria-hidden') {
            this.setAttribute('data-modal-visible', value === 'false' ? 'false' : 'true');
            return;
        }
        originalSetAttribute.call(this, name, value);
    };
    
    const originalRemoveAttribute = modalElement.removeAttribute;
    modalElement.removeAttribute = function(name) {
        if (name === 'aria-hidden') {
            this.setAttribute('data-modal-visible', 'false');
            return;
        }
        originalRemoveAttribute.call(this, name);
    };
    
    // Set up focus management
    modalElement.addEventListener('show.bs.modal', function() {
        // Focus the first focusable element after a short delay
        setTimeout(() => {
            const focusable = modalElement.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
            if (focusable) {
                focusable.focus();
            }
        }, 50);
    });
    
    // Handle focus return on hide
    modalElement.addEventListener('hidden.bs.modal', function() {
        const triggerButton = document.activeElement;
        setTimeout(() => {
            if (triggerButton && triggerButton.matches('[data-bs-toggle="modal"]')) {
                triggerButton.focus();
            }
        }, 10);
    });
    
    return modalInstance;
}

// Initialize all modals on the page
export function initAllAccessibleModals() {
    document.querySelectorAll('.modal').forEach(modal => {
        initAccessibleModal(modal);
    });
}

// Auto-initialize modals when the DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAllAccessibleModals);
} else {
    initAllAccessibleModals();
}
