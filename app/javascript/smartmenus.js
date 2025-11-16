export function initSmartmenus() {
  // Initialize section tab auto-scroll on scroll spy
  initSectionTabAutoScroll();
  
  // Initialize time-based menu restrictions
  initMenuTimeRestrictions();
  
  function smlink(cell, formatterParams) {
    const id = cell.getValue();
    const name = cell.getRow();
    const rowData = cell.getRow().getData('data').fqlinkname;
    return "<a class='link-dark' href='/smartmenus/" + id + "'>" + rowData + '</a>';
  }
  const regionNames = new Intl.DisplayNames(['en'], { type: 'region' });

  if ($('#smartmenu-table').length) {
    const smartmenuTable = new Tabulator('#smartmenu-table', {
      pagination: 'local',
      paginationSize: 20,
      movableColumns: true,
      paginationCounter: 'rows',
      dataLoader: false,
      maxHeight: '100%',
      responsiveLayout: true,
      layout: 'fitDataStretch',
      ajaxURL: '/smartmenus.json',
      ajaxConfig: 'GET',
      movableRows: false,
      columns: [
        {
          title: '',
          hozAlign: 'right',
          maxWidth: 100,
          field: 'restaurant.country',
          headerFilter: 'input',
          mutator: function (value) {
            console.log(value);
            if (value.toUpperCase() == 'GB') {
              return 'UK';
            }
            if (value.toUpperCase() == 'US') {
              return 'USA';
            }
            return regionNames.of(value.toUpperCase()) || 'Unknown';
          },
        },
        { title: 'Address', field: 'restaurant.address1', headerFilter: 'input', widthGrow: 1 },
        {
          title: 'Menu',
          field: 'slug',
          responsive: 0,
          formatter: smlink,
          hozAlign: 'left',
          headerFilter: 'input',
          widthGrow: 3,
          headerFilterFunc: function (headerValue, rowValue, rowData) {
            const filterValue = headerValue.toLowerCase();
            return (
              rowData.restaurant.name.toLowerCase().includes(filterValue) ||
              rowData.menu.name.toLowerCase().includes(filterValue)
            );
          },
        },
      ],
    });
  }
}

/**
 * Initialize auto-scroll for section tabs when scrollspy activates
 * Ensures the active tab is visible in the horizontal scrollable container
 */
function initSectionTabAutoScroll() {
  const tabsContainer = document.querySelector('.sections-tabs-container');
  const scrollspyElement = document.querySelector('[data-bs-spy="scroll"]');
  
  if (!tabsContainer || !scrollspyElement) return;
  
  // Listen for Bootstrap scrollspy activation events
  scrollspyElement.addEventListener('activate.bs.scrollspy', function(event) {
    // Small delay to ensure the active class has been applied
    setTimeout(() => {
      const activeTab = tabsContainer.querySelector('.section-tab.active');
      
      if (activeTab) {
        // Calculate the position to scroll to
        const containerRect = tabsContainer.getBoundingClientRect();
        const tabRect = activeTab.getBoundingClientRect();
        
        // Calculate how much we need to scroll
        const scrollLeft = tabsContainer.scrollLeft;
        const tabLeft = tabRect.left - containerRect.left;
        const tabWidth = tabRect.width;
        const containerWidth = containerRect.width;
        
        // Center the active tab in the viewport if possible
        const targetScroll = scrollLeft + tabLeft - (containerWidth / 2) + (tabWidth / 2);
        
        // Smooth scroll to the active tab
        tabsContainer.scrollTo({
          left: targetScroll,
          behavior: 'smooth'
        });
      }
    }, 50);
  });
  
  // Also handle manual clicks on section tabs
  const sectionTabs = tabsContainer.querySelectorAll('.section-tab');
  sectionTabs.forEach(tab => {
    tab.addEventListener('click', function(event) {
      // Let the default behavior happen, then scroll the tab into view
      setTimeout(() => {
        const containerRect = tabsContainer.getBoundingClientRect();
        const tabRect = tab.getBoundingClientRect();
        const scrollLeft = tabsContainer.scrollLeft;
        const tabLeft = tabRect.left - containerRect.left;
        const tabWidth = tabRect.width;
        const containerWidth = containerRect.width;
        const targetScroll = scrollLeft + tabLeft - (containerWidth / 2) + (tabWidth / 2);
        
        tabsContainer.scrollTo({
          left: targetScroll,
          behavior: 'smooth'
        });
      }, 100);
    });
  });
}

/**
 * Initialize time-based menu restrictions
 * Disables "Add to Order" buttons for menu items in restricted sections
 * when the current time is outside the section's available time range
 */
function initMenuTimeRestrictions() {
  // Get current time in minutes since midnight
  const date = new Date();
  const currentOffset = date.getHours() * 60 + date.getMinutes();
  
  // Find all "Add to Order" buttons
  const addToOrderButtons = document.querySelectorAll('.addItemToOrder');
  
  if (addToOrderButtons.length === 0) return;
  
  // Check each button's time restrictions
  addToOrderButtons.forEach(button => {
    const fromOffset = parseInt(button.getAttribute('data-bs-menusection_from_offset'));
    const toOffset = parseInt(button.getAttribute('data-bs-menusection_to_offset'));
    
    // If button has time restrictions (from/to offsets are set)
    if (!isNaN(fromOffset) && !isNaN(toOffset)) {
      // Disable button if current time is outside the valid range
      if (currentOffset < fromOffset || currentOffset > toOffset) {
        button.disabled = true;
        button.classList.add('disabled');
        button.style.opacity = '0.5';
        button.style.cursor = 'not-allowed';
        
        // Add tooltip to explain why it's disabled
        button.setAttribute('title', 'This item is not available at this time');
      } else {
        // Only enable button if we're within the valid time range
        // AND there's a table selected (check if button has data-bs-ordr_id)
        const hasOrder = button.getAttribute('data-bs-ordr_id');
        if (hasOrder) {
          button.disabled = false;
          button.classList.remove('disabled');
          button.style.opacity = '';
          button.style.cursor = '';
          button.removeAttribute('title');
        }
      }
    }
  });
  
  // Re-check restrictions every minute to update button states
  setInterval(() => {
    const date = new Date();
    const currentOffset = date.getHours() * 60 + date.getMinutes();
    
    addToOrderButtons.forEach(button => {
      const fromOffset = parseInt(button.getAttribute('data-bs-menusection_from_offset'));
      const toOffset = parseInt(button.getAttribute('data-bs-menusection_to_offset'));
      
      if (!isNaN(fromOffset) && !isNaN(toOffset)) {
        if (currentOffset < fromOffset || currentOffset > toOffset) {
          button.disabled = true;
          button.classList.add('disabled');
          button.style.opacity = '0.5';
          button.style.cursor = 'not-allowed';
          button.setAttribute('title', 'This item is not available at this time');
        } else {
          // Only enable button if there's a table selected (check if button has data-bs-ordr_id)
          const hasOrder = button.getAttribute('data-bs-ordr_id');
          if (hasOrder) {
            button.disabled = false;
            button.classList.remove('disabled');
            button.style.opacity = '';
            button.style.cursor = '';
            button.removeAttribute('title');
          }
        }
      }
    });
  }, 60000); // Check every minute (60000 milliseconds)
}
