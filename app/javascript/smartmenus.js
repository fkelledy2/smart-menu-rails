// Wait for both DOM content and Turbo to be ready
function initializeSmartMenus() {
    // Ensure jQuery is available
    if (typeof $ === 'undefined') {
        console.warn('jQuery is not loaded. Waiting for it to be available...');
        setTimeout(initializeSmartMenus, 100);
        return;
    }

    function smlink(cell, formatterParams) {
        var id = cell.getValue();
        var rowData = cell.getRow().getData("data").fqlinkname;
        return `<a class='link-dark' href='/smartmenus/${id}'>${rowData}</a>`;
    }

    const regionNames = new Intl.DisplayNames(['en'], { type: 'region' });

    if ($("#smartmenu-table").length > 0) {
        try {
            var smartmenuTable = new Tabulator("#smartmenu-table", {
                pagination: "local",
                paginationSize: 20,
                movableColumns: true,
                paginationCounter: "rows",
                dataLoader: false,
                maxHeight: "100%",
                responsiveLayout: true,
                layout: "fitDataStretch",
                ajaxURL: "/smartmenus.json",
                ajaxConfig: "GET",
                movableRows: false,
                columns: [
                    { 
                        title: "", 
                        hozAlign: "right", 
                        maxWidth: 100, 
                        field: "restaurant.country", 
                        headerFilter: "input",
                        mutator: function(value) {
                            if (!value) return "Unknown";
                            const upperValue = String(value).toUpperCase();
                            if (upperValue === 'GB') return "UK";
                            if (upperValue === 'US') return "USA";
                            return regionNames.of(upperValue) || "Unknown";
                        }
                    },
                    { 
                        title: "Address", 
                        field: "restaurant.address1", 
                        headerFilter: "input", 
                        widthGrow: 1 
                    },
                    {
                        title: "Menu", 
                        field: "slug", 
                        responsive: 0, 
                        formatter: smlink, 
                        hozAlign: "left", 
                        headerFilter: "input", 
                        widthGrow: 3,
                        headerFilterFunc: function(headerValue, rowValue, rowData) {
                            if (!headerValue) return true;
                            const filterValue = String(headerValue).toLowerCase();
                            const restaurantName = String(rowData.restaurant?.name || '').toLowerCase();
                            const menuName = String(rowData.menu?.name || '').toLowerCase();
                            return restaurantName.includes(filterValue) || menuName.includes(filterValue);
                        }
                    }
                ]
            });
        } catch (error) {
            console.error('Error initializing Tabulator:', error);
        }
    }
}

// Initialize on page load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeSmartMenus);
} else {
    initializeSmartMenus();
}

// Re-initialize on Turbo page changes
document.addEventListener('turbo:load', initializeSmartMenus);