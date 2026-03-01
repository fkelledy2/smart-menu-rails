import { Controller } from "@hotwired/stimulus"

/**
 * Camera Capture Stimulus Controller
 * Opens the device camera via getUserMedia, shows a live viewfinder,
 * lets the user take a photo, preview it, and inject it into a file input
 * for standard form submission (works with Shrine uploads).
 *
 * Usage:
 * <div data-controller="camera-capture"
 *      data-camera-capture-file-input-value="#menuitem_image">
 *   <button data-action="click->camera-capture#open">Take Photo</button>
 *   <!-- viewfinder, canvas, preview are auto-created -->
 * </div>
 */
export default class extends Controller {
  static targets = ["viewfinder", "canvas", "preview", "previewImg", "overlay",
                     "openBtn", "captureBtn", "retakeBtn", "acceptBtn", "status"]

  static values = {
    fileInput: { type: String, default: "" } // CSS selector for the <input type="file">
  }

  connect() {
    this.stream = null
    this.capturedFile = null
  }

  disconnect() {
    this._stopStream()
  }

  // --- Public actions ---

  async open(e) {
    e.preventDefault()

    // Check for camera support
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this._showStatus("Camera not supported in this browser. Please use the file upload instead.")
      return
    }

    this._showOverlay()

    try {
      // Prefer rear camera (environment) for photographing food
      this.stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment", width: { ideal: 1280 }, height: { ideal: 960 } },
        audio: false
      })

      const video = this.viewfinderTarget
      video.srcObject = this.stream
      await video.play()

      this._showPhase("viewfinder")
    } catch (err) {
      console.error("[CameraCapture] getUserMedia failed:", err)
      if (err.name === "NotAllowedError") {
        this._showStatus("Camera access denied. Please allow camera permissions and try again.")
      } else {
        this._showStatus(`Could not access camera: ${err.message}`)
      }
      this._hideOverlay()
    }
  }

  capture(e) {
    e.preventDefault()

    const video = this.viewfinderTarget
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")

    // Set canvas to video resolution
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height)

    // Stop camera stream immediately after capture
    this._stopStream()

    // Convert to blob and show preview
    canvas.toBlob((blob) => {
      if (!blob) {
        this._showStatus("Failed to capture image. Please try again.")
        return
      }

      const timestamp = new Date().toISOString().replace(/[:.]/g, "-")
      this.capturedFile = new File([blob], `camera-${timestamp}.jpg`, { type: "image/jpeg" })

      // Show preview
      const url = URL.createObjectURL(blob)
      this.previewImgTarget.src = url
      this._showPhase("preview")
    }, "image/jpeg", 0.92)
  }

  retake(e) {
    e.preventDefault()
    this.capturedFile = null

    // Revoke previous preview URL
    const img = this.previewImgTarget
    if (img.src.startsWith("blob:")) URL.revokeObjectURL(img.src)
    img.src = ""

    // Re-open camera
    this.open(e)
  }

  accept(e) {
    e.preventDefault()

    if (!this.capturedFile) return

    // Inject file into the target file input using DataTransfer
    const selector = this.fileInputValue
    const fileInput = selector ? document.querySelector(selector) : null

    if (fileInput) {
      const dt = new DataTransfer()
      dt.items.add(this.capturedFile)
      fileInput.files = dt.files

      // Trigger change event so any listeners (Shrine, etc.) pick it up
      fileInput.dispatchEvent(new Event("change", { bubbles: true }))
    }

    // Also update the visible image preview on the page if present
    const existingPreview = document.querySelector(".menuitem-image-preview-2025")
    const placeholder = document.querySelector(".menuitem-image-placeholder")
    if (existingPreview) {
      existingPreview.src = URL.createObjectURL(this.capturedFile)
    } else if (placeholder) {
      const img = document.createElement("img")
      img.src = URL.createObjectURL(this.capturedFile)
      img.className = "menuitem-image-preview-2025 mb-3"
      img.alt = "Captured photo"
      placeholder.replaceWith(img)
    }

    this._hideOverlay()
    this._showStatus("Photo captured — remember to save the form.")
  }

  cancel(e) {
    e.preventDefault()
    this._stopStream()
    this.capturedFile = null
    this._hideOverlay()
  }

  // --- Internal ---

  _showPhase(phase) {
    // phase: "viewfinder" or "preview"
    const isViewfinder = phase === "viewfinder"

    this.viewfinderTarget.classList.toggle("d-none", !isViewfinder)
    this.captureBtnTarget.classList.toggle("d-none", !isViewfinder)

    this.previewTarget.classList.toggle("d-none", isViewfinder)
    this.retakeBtnTarget.classList.toggle("d-none", isViewfinder)
    this.acceptBtnTarget.classList.toggle("d-none", isViewfinder)
  }

  _showOverlay() {
    this.overlayTarget.classList.remove("d-none")
    document.body.style.overflow = "hidden"
  }

  _hideOverlay() {
    this.overlayTarget.classList.add("d-none")
    document.body.style.overflow = ""
    this._stopStream()
  }

  _stopStream() {
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop())
      this.stream = null
    }
    if (this.hasViewfinderTarget) {
      this.viewfinderTarget.srcObject = null
    }
  }

  _showStatus(msg) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = msg
      this.statusTarget.classList.remove("d-none")
      setTimeout(() => { this.statusTarget.classList.add("d-none") }, 5000)
    }
  }
}
