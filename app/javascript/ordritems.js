export function initOrdritems() {
  let restaurantCurrencySymbol = '$';
  if ($('#restaurantCurrency').length) {
    restaurantCurrencySymbol = $('#restaurantCurrency').text();
  }
  if ($('#orderitem-table').length) {
    const ordrTableElement = document.getElementById('orderitem-table');
    const restaurantId = ordrTableElement.getAttribute('data-bs-restaurant_id');
    const orderItemTable = new Tabulator('#orderitem-table', {
      dataLoader: false,
      maxHeight: '100%',
      paginationSize: 20,
      responsiveLayout: true,
      layout: 'fitDataFill',
      groupBy: 'ordr.id',
      ajaxURL: `/restaurants/${restaurantId}/ordritems.json`,
      columns: [
        {
          title: 'Order',
          field: 'ordr.id',
          frozen: true,
          width: 200,
          responsive: 0,
          formatter: function (cell, formatterParams) {
            const id = cell.getValue();
            const restaurantId = $('#currentRestaurant').text();
            return `<a href='/restaurants/${restaurantId}/ordrs/${id}'>${id}</a>`;
          },
        },
        {
          title: 'Menu Item',
          field: 'menuitem.id',
          responsive: 0,
          formatter: function (cell, formatterParams) {
            const menuitemId = cell.getValue();
            const rowData = cell.getRow().getData();
            const menuitemName = rowData.menuitem?.name || menuitemId;
            const menusectionId = rowData.menuitem?.menusection;
            const menuId = rowData.menuitem?.menu;
            const restaurantId = rowData.menuitem?.restaurant || rowData.restaurant?.id;

            if (restaurantId && menuId && menusectionId) {
              return `<a class='link-dark' href='/restaurants/${restaurantId}/menus/${menuId}/menusections/${menusectionId}/menuitems/${menuitemId}/edit'>${menuitemName}</a>`;
            } else {
              // Fallback to old route if context not available
              return `<a class='link-dark' href='/menuitems/${menuitemId}/edit'>${menuitemName}</a>`;
            }
          },
        },
        {
          title: 'Price',
          field: 'menuitem.price',
          formatter: 'money',
          width: 200,
          hozAlign: 'right',
          headerHozAlign: 'right',
          bottomCalc: 'sum',
          bottomCalcParams: { precision: 2 },
          formatterParams: {
            decimal: '.',
            thousand: ',',
            symbol: restaurantCurrencySymbol,
            negativeSign: true,
            precision: 2,
          },
        },
        {
          title: 'Created',
          field: 'created_at',
          responsive: 4,
          width: 200,
          hozAlign: 'right',
          headerHozAlign: 'right',
          formatter: 'datetime',
          formatterParams: {
            inputFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat: 'dd/MM/yyyy HH:mm',
            invalidPlaceholder: '(invalid date)',
          },
        },
        {
          title: 'Updated',
          field: 'updated_at',
          responsive: 5,
          width: 200,
          hozAlign: 'right',
          headerHozAlign: 'right',
          formatter: 'datetime',
          formatterParams: {
            inputFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            outputFormat: 'dd/MM/yyyy HH:mm',
            invalidPlaceholder: '(invalid date)',
          },
        },
      ],
    });
    //trigger an alert message when the row is clicked
    orderItemTable.on('rowClick', function (e, row) {});
  }
}
