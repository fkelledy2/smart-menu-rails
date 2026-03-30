import { Controller } from '@hotwired/stimulus';
import consumer from '../channels/consumer';

/**
 * Order Notes Controller
 *
 * Manages real-time updates for order notes via ActionCable.
 * Listens to OrderChannel for note_created, note_updated, and note_deleted events.
 *
 * Integration Points:
 * - Rendered by: app/views/ordrnotes/_order_notes_section.html.erb
 * - WebSocket: Subscribes to OrderChannel for the specific order
 * - Backend: app/controllers/ordrnotes_controller.rb broadcasts note changes
 */
export default class extends Controller {
  static targets = ['notesList', 'emptyState'];
  static values = {
    orderId: String,
    restaurantId: String,
  };

  connect() {
    this.subscribeToOrderChannel();
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  subscribeToOrderChannel() {
    if (!this.orderIdValue) {
      console.warn('[OrderNotes] No order ID provided, skipping subscription');
      return;
    }

    this.subscription = consumer.subscriptions.create(
      {
        channel: 'OrderChannel',
        order_id: this.orderIdValue,
      },
      {
        connected: () => {},

        disconnected: () => {},

        received: (data) => {
          if (data.action === 'note_created') {
            this.handleNoteCreated(data);
          } else if (data.action === 'note_updated') {
            this.handleNoteUpdated(data);
          } else if (data.action === 'note_deleted') {
            this.handleNoteDeleted(data);
          }
        },
      }
    );
  }

  handleNoteCreated(data) {
    // Hide empty state if it exists
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.style.display = 'none';
    }

    // Create notes list if it doesn't exist
    if (!this.hasNotesListTarget) {
      const notesContainer = this.element.querySelector('.card-body');
      const notesList = document.createElement('div');
      notesList.className = 'notes-list';
      notesList.setAttribute('data-order-notes-target', 'notesList');
      notesContainer.appendChild(notesList);
    }

    // Insert the new note at the top (notes are sorted by priority/created_at desc)
    if (this.hasNotesListTarget && data.note_html) {
      this.notesListTarget.insertAdjacentHTML('afterbegin', data.note_html);

      // Highlight the new note briefly
      const newNote = this.notesListTarget.querySelector(`[data-note-id="${data.note_id}"]`);
      if (newNote) {
        newNote.classList.add('note-highlight');
        setTimeout(() => {
          newNote.classList.remove('note-highlight');
        }, 2000);
      }
    }
  }

  handleNoteUpdated(data) {
    const existingNote = this.element.querySelector(`[data-note-id="${data.note_id}"]`);
    if (existingNote && data.note_html) {
      existingNote.outerHTML = data.note_html;

      // Highlight the updated note briefly
      const updatedNote = this.element.querySelector(`[data-note-id="${data.note_id}"]`);
      if (updatedNote) {
        updatedNote.classList.add('note-highlight');
        setTimeout(() => {
          updatedNote.classList.remove('note-highlight');
        }, 2000);
      }
    }
  }

  handleNoteDeleted(data) {
    const noteToRemove = this.element.querySelector(`[data-note-id="${data.note_id}"]`);
    if (noteToRemove) {
      // Fade out animation
      noteToRemove.style.transition = 'opacity 0.3s ease-out';
      noteToRemove.style.opacity = '0';

      setTimeout(() => {
        noteToRemove.remove();

        // Show empty state if no notes left
        if (this.hasNotesListTarget && this.notesListTarget.children.length === 0) {
          if (this.hasEmptyStateTarget) {
            this.emptyStateTarget.style.display = 'block';
          }
        }
      }, 300);
    }
  }
}
