export function initSmartmenus() {
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
