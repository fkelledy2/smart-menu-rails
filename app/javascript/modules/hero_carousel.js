// Hero Carousel Module
// Handles the dissolving background image carousel on the homepage

export class HeroCarousel {
  constructor(containerSelector, options = {}) {
    this.container = document.querySelector(containerSelector);
    if (!this.container) return;

    this.options = {
      imageInterval: options.imageInterval || 10000, // 10 seconds for images
      ctaInterval: options.ctaInterval || 5000, // 5 seconds for CTA
      transitionDuration: options.transitionDuration || 2000, // 2 seconds fade
      images: options.images || this.getDefaultImages(),
      ctaContent: options.ctaContent || this.getDefaultCTAContent(),
    };

    this.currentImageIndex = 0;
    this.currentCtaIndex = 0;
    this.backgrounds = [];
    this.imageIntervalId = null;
    this.ctaIntervalId = null;

    // Get CTA elements
    this.ctaTitle = this.container.querySelector('[data-cta-title]');
    this.ctaBody = this.container.querySelector('[data-cta-body]');

    this.init();
  }

  getDefaultImages() {
    // Try to get images from backend first
    const heroImagesData = this.container.dataset.heroImages;

    if (heroImagesData) {
      try {
        const backendImages = JSON.parse(heroImagesData);
        if (backendImages && backendImages.length > 0) {
          console.log('[HeroCarousel] Using', backendImages.length, 'backend-approved images');
          // Extract URLs from backend data and randomize
          const imageUrls = backendImages.map((img) => img.url);
          return this.shuffleArray(imageUrls);
        }
      } catch (e) {
        console.warn('[HeroCarousel] Failed to parse backend images, using fallback:', e);
      }
    }

    // Fallback to hardcoded Pexels images if no backend images
    console.log('[HeroCarousel] Using fallback Pexels images');
    const images = [
      'https://images.pexels.com/photos/1581384/pexels-photo-1581384.jpeg?auto=compress&cs=tinysrgb&w=1920',
      'https://images.pexels.com/photos/696218/pexels-photo-696218.jpeg?auto=compress&cs=tinysrgb&w=1920',
      'https://images.pexels.com/photos/941861/pexels-photo-941861.jpeg?auto=compress&cs=tinysrgb&w=1920',
      'https://images.pexels.com/photos/67468/pexels-photo-67468.jpeg?auto=compress&cs=tinysrgb&w=1920',
      'https://images.pexels.com/photos/3201921/pexels-photo-3201921.jpeg?auto=compress&cs=tinysrgb&w=1920',
      'https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg?auto=compress&cs=tinysrgb&w=1920',
      'https://images.pexels.com/photos/1307698/pexels-photo-1307698.jpeg?auto=compress&cs=tinysrgb&w=1920',
      'https://images.pexels.com/photos/2788792/pexels-photo-2788792.jpeg?auto=compress&cs=tinysrgb&w=1920',
      'https://images.pexels.com/photos/1126728/pexels-photo-1126728.jpeg?auto=compress&cs=tinysrgb&w=1920',
      'https://images.pexels.com/photos/2788799/pexels-photo-2788799.jpeg?auto=compress&cs=tinysrgb&w=1920',
    ];

    // Randomize the order using Fisher-Yates shuffle
    return this.shuffleArray(images);
  }

  getDefaultCTAContent() {
    // Get CTA content from data attributes on the container
    const cta1Title = this.container.dataset.cta1Title || 'Add intelligence to your restaurant';
    const cta1Body =
      this.container.dataset.cta1Body || 'Create beautiful digital menus and streamline ordering.';
    const cta2Title = this.container.dataset.cta2Title || 'Intelligent features';
    const cta2Body =
      this.container.dataset.cta2Body ||
      'Smart ordering, images, translations, availability and more.';

    return [
      { title: cta1Title, body: cta1Body },
      { title: cta2Title, body: cta2Body },
    ];
  }

  shuffleArray(array) {
    // Fisher-Yates shuffle algorithm for true randomization
    const shuffled = [...array]; // Create a copy
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
  }

  init() {
    console.log('[HeroCarousel] Creating background layers...');
    this.createBackgroundLayers();
    console.log('[HeroCarousel] Starting carousel with', this.backgrounds.length, 'images');
    this.startCarousel();

    // Pause on hover (optional)
    this.container.addEventListener('mouseenter', () => this.pause());
    this.container.addEventListener('mouseleave', () => this.resume());

    console.log('[HeroCarousel] Init complete. CTA elements:', {
      title: this.ctaTitle,
      body: this.ctaBody,
    });
  }

  createBackgroundLayers() {
    // Create a background div for each image
    this.options.images.forEach((imageUrl, index) => {
      const bgDiv = document.createElement('div');
      bgDiv.className = 'hero-background';
      bgDiv.style.backgroundImage = `url('${imageUrl}')`;

      // Make first image active
      if (index === 0) {
        bgDiv.classList.add('active');
      }

      this.container.insertBefore(bgDiv, this.container.firstChild);
      this.backgrounds.push(bgDiv);
    });
  }

  startCarousel() {
    console.log(
      '[HeroCarousel] Starting timers - Images:',
      this.options.imageInterval + 'ms, CTA:',
      this.options.ctaInterval + 'ms'
    );

    // Start image carousel
    this.imageIntervalId = setInterval(() => {
      this.nextImage();
    }, this.options.imageInterval);

    // Start CTA carousel (independent timer)
    this.ctaIntervalId = setInterval(() => {
      this.nextCTA();
    }, this.options.ctaInterval);
  }

  nextImage() {
    console.log('[HeroCarousel] Transitioning from image', this.currentImageIndex, 'to next image');

    // Remove active class from current image
    this.backgrounds[this.currentImageIndex].classList.remove('active');

    // Move to next image
    this.currentImageIndex = (this.currentImageIndex + 1) % this.backgrounds.length;

    // Add active class to next image
    this.backgrounds[this.currentImageIndex].classList.add('active');

    console.log('[HeroCarousel] Now showing image', this.currentImageIndex);
  }

  nextCTA() {
    console.log('[HeroCarousel] Changing CTA from index', this.currentCtaIndex);

    // Move to next CTA
    this.currentCtaIndex = (this.currentCtaIndex + 1) % this.options.ctaContent.length;

    // Update CTA content
    this.updateCTAContent();
  }

  updateCTAContent() {
    if (!this.ctaTitle || !this.ctaBody) return;

    // Get current CTA content
    const currentCTA = this.options.ctaContent[this.currentCtaIndex];

    console.log(
      '[HeroCarousel] Updating CTA to index',
      this.currentCtaIndex,
      ':',
      currentCTA.title
    );

    // Fade out
    this.ctaTitle.style.opacity = '0';
    this.ctaBody.style.opacity = '0';

    // Update content after fade out
    setTimeout(() => {
      this.ctaTitle.textContent = currentCTA.title;
      this.ctaBody.innerHTML = `<strong>${currentCTA.body}</strong>`;

      // Fade in
      this.ctaTitle.style.opacity = '1';
      this.ctaBody.style.opacity = '1';
    }, 500); // Half of transition duration
  }

  pause() {
    console.log('[HeroCarousel] Pausing carousel');
    if (this.imageIntervalId) {
      clearInterval(this.imageIntervalId);
      this.imageIntervalId = null;
    }
    if (this.ctaIntervalId) {
      clearInterval(this.ctaIntervalId);
      this.ctaIntervalId = null;
    }
  }

  resume() {
    console.log('[HeroCarousel] Resuming carousel');
    if (!this.imageIntervalId && !this.ctaIntervalId) {
      this.startCarousel();
    }
  }

  destroy() {
    this.pause();
    this.backgrounds.forEach((bg) => bg.remove());
    this.backgrounds = [];
  }
}

// Auto-initialize on DOM ready
function initHeroCarousel() {
  console.log('[HeroCarousel] Initializing...');
  const container = document.querySelector('.hero-carousel');

  if (!container) {
    console.log('[HeroCarousel] Container not found, skipping initialization');
    return;
  }

  console.log('[HeroCarousel] Container found, creating carousel');
  const heroCarousel = new HeroCarousel('.hero-carousel', {
    imageInterval: 10000, // 10 seconds for background images
    ctaInterval: 5000, // 5 seconds for CTA text
    transitionDuration: 2000, // 2 second dissolve
  });
  console.log('[HeroCarousel] Carousel initialized successfully');
}

// Try multiple initialization methods for compatibility
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initHeroCarousel);
} else {
  // DOM already loaded
  initHeroCarousel();
}

// Also try with turbo:load for Turbo-powered apps
document.addEventListener('turbo:load', initHeroCarousel);
