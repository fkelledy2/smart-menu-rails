import { Controller } from "@hotwired/stimulus"

/**
 * Bottom Sheet Stimulus Controller
 * A mobile-friendly bottom sheet with peek/half/full snap points.
 * Supports swipe-to-dismiss and swipe-to-expand gestures.
 *
 * Usage:
 * <div data-controller="bottom-sheet"
 *      data-bottom-sheet-peek-value="64"
 *      data-bottom-sheet-half-value="50"
 *      data-bottom-sheet-initial-value="peek">
 *   <div data-bottom-sheet-target="handle" data-action="click->bottom-sheet#toggle">
 *     ─── Drag handle ───
 *   </div>
 *   <div data-bottom-sheet-target="content">
 *     Sheet content here
 *   </div>
 * </div>
 */
export default class extends Controller {
  static targets = ["handle", "content", "backdrop"]

  static values = {
    peek:    { type: Number, default: 64 },   // px height in peek state
    half:    { type: Number, default: 50 },    // % of viewport in half state
    initial: { type: String, default: "peek" } // peek | half | full | closed
  }

  connect() {
    this.state = this.initialValue
    this.startY = 0
    this.currentY = 0
    this.isDragging = false

    this.applyState()
    this.bindTouchEvents()

    // Restore to peek after any Bootstrap modal closes
    this._onModalHidden = () => {
      if (this.state === "closed" && this.initialValue !== "closed") {
        this.setState("peek")
      }
    }
    document.addEventListener("hidden.bs.modal", this._onModalHidden)

    console.log("[BottomSheet] connected", { initial: this.state })
  }

  disconnect() {
    this.unbindTouchEvents()
    if (this._onModalHidden) {
      document.removeEventListener("hidden.bs.modal", this._onModalHidden)
    }
  }

  // --- Public actions ---

  toggle() {
    const transitions = {
      closed: "peek",
      peek:   "half",
      half:   "full",
      full:   "peek"
    }
    this.setState(transitions[this.state] || "peek")
  }

  open()  { this.setState("half") }
  close() { this.setState("closed") }
  peek()  { this.setState("peek") }
  expand() { this.setState("full") }

  // --- State management ---

  setState(newState) {
    const oldState = this.state
    this.state = newState
    this.applyState()
    this.dispatch("stateChanged", { detail: { from: oldState, to: newState } })
  }

  applyState() {
    const el = this.element

    // Remove all state classes
    el.classList.remove("bottom-sheet--closed", "bottom-sheet--peek", "bottom-sheet--half", "bottom-sheet--full")
    el.classList.add(`bottom-sheet--${this.state}`)

    switch (this.state) {
      case "closed":
        el.style.transform = "translateY(100%)"
        this.hideBackdrop()
        break
      case "peek":
        el.style.transform = `translateY(calc(100% - ${this.peekValue}px))`
        this.hideBackdrop()
        break
      case "half":
        el.style.transform = `translateY(${100 - this.halfValue}%)`
        this.showBackdrop()
        break
      case "full":
        el.style.transform = "translateY(0)"
        this.showBackdrop()
        break
    }
  }

  // --- Touch / drag handling ---

  bindTouchEvents() {
    if (!this.hasHandleTarget) return

    this._onTouchStart = this.onTouchStart.bind(this)
    this._onTouchMove  = this.onTouchMove.bind(this)
    this._onTouchEnd   = this.onTouchEnd.bind(this)

    this.handleTarget.addEventListener("touchstart", this._onTouchStart, { passive: true })
    document.addEventListener("touchmove", this._onTouchMove, { passive: false })
    document.addEventListener("touchend", this._onTouchEnd, { passive: true })
  }

  unbindTouchEvents() {
    if (!this.hasHandleTarget) return

    this.handleTarget.removeEventListener("touchstart", this._onTouchStart)
    document.removeEventListener("touchmove", this._onTouchMove)
    document.removeEventListener("touchend", this._onTouchEnd)
  }

  onTouchStart(e) {
    this.isDragging = true
    this.startY = e.touches[0].clientY
    this.element.style.transition = "none"
  }

  onTouchMove(e) {
    if (!this.isDragging) return
    e.preventDefault()

    this.currentY = e.touches[0].clientY
    const delta = this.currentY - this.startY
    const vh = window.innerHeight

    // Translate based on current state + drag delta
    let baseOffset
    switch (this.state) {
      case "peek": baseOffset = vh - this.peekValue; break
      case "half": baseOffset = vh * (1 - this.halfValue / 100); break
      case "full": baseOffset = 0; break
      default:     baseOffset = vh; break
    }

    const newOffset = Math.max(0, Math.min(vh, baseOffset + delta))
    this.element.style.transform = `translateY(${newOffset}px)`
  }

  onTouchEnd() {
    if (!this.isDragging) return
    this.isDragging = false

    this.element.style.transition = ""
    const delta = this.currentY - this.startY
    const threshold = 50

    if (delta > threshold) {
      // Swiped down
      const downMap = { full: "half", half: "peek", peek: "closed" }
      this.setState(downMap[this.state] || "closed")
    } else if (delta < -threshold) {
      // Swiped up
      const upMap = { closed: "peek", peek: "half", half: "full" }
      this.setState(upMap[this.state] || "full")
    } else {
      // Snap back
      this.applyState()
    }
  }

  // --- Backdrop ---

  showBackdrop() {
    if (!this.hasBackdropTarget) return
    this.backdropTarget.classList.add("bottom-sheet-backdrop--visible")
  }

  hideBackdrop() {
    if (!this.hasBackdropTarget) return
    this.backdropTarget.classList.remove("bottom-sheet-backdrop--visible")
  }
}
