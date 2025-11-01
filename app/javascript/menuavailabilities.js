import { initTomSelectIfNeeded } from './tomselect_helper';

export function initMenuavailabilities() {
  if ($('#menuavailability_dayofweek').length) {
    initTomSelectIfNeeded('#menuavailability_dayofweek', {});
  }

  if ($('#menuavailability_status').length) {
    initTomSelectIfNeeded('#menuavailability_status', {});
  }

  if ($('#menuavailability_menu_id').length) {
    initTomSelectIfNeeded('#menuavailability_menu_id', {});
  }
  if ($('#menuTabs').length) {
    function status(cell, formatterParams) {
      return cell.getRow().getData('data').status.toUpperCase();
    }
    function link(cell, formatterParams) {
      const id = cell.getValue();
      const name = cell.getRow();
      const rowData = cell.getRow().getData('data').dayofweek;

      // Get menu and restaurant ID from table element for nested routes
      const tableElement = cell.getTable().element;
      const menuId = tableElement.dataset.menu || tableElement.dataset.bsMenu;
      const restaurantId = tableElement.dataset.restaurant || tableElement.dataset.bsRestaurant;

      if (menuId && restaurantId) {
        return (
          "<a class='link-dark' href='/restaurants/" +
          restaurantId +
          '/menus/' +
          menuId +
          '/menuavailabilities/' +
          id +
          "/edit'>" +
          rowData +
          '</a>'
        );
      } else {
        // Fallback to old route if context not available
        return (
          "<a class='link-dark' href='/menuavailabilities/" + id + "/edit'>" + rowData + '</a>'
        );
      }
    }
    const menuAvailabilityTableElement = document.getElementById('menu-menuavailability-table');
    if (!menuAvailabilityTableElement) return; // Exit if element doesn't exist
    const menuId = menuAvailabilityTableElement.getAttribute('data-bs-menu');
    const restaurantId = menuAvailabilityTableElement.getAttribute('data-bs-restaurant');
    const menuavailabilityTable = new Tabulator('#menu-menuavailability-table', {
      dataLoader: false,
      maxHeight: '100%',
      responsiveLayout: true,
      layout: 'fitDataStretch',
      ajaxURL: '/restaurants/' + restaurantId + '/menus/' + menuId + '/menuavailabilities.json',
      initialSort: [{ column: 'sequence', dir: 'asc' }],
      movableRows: true,
      columns: [
        {
          formatter: 'rowSelection',
          titleFormatter: 'rowSelection',
          width: 30,
          frozen: true,
          headerHozAlign: 'left',
          hozAlign: 'left',
          headerSort: false,
          cellClick: function (e, cell) {
            cell.getRow().toggleSelect();
          },
        },
        {
          rowHandle: true,
          formatter: 'handle',
          headerSort: false,
          frozen: true,
          responsive: 0,
          width: 30,
          minWidth: 30,
        },
        {
          title: '',
          field: 'sequence',
          visible: false,
          formatter: 'rownum',
          hozAlign: 'right',
          headerHozAlign: 'right',
          headerSort: false,
        },
        { title: 'Day of Week', field: 'id', responsive: 0, formatter: link, hozAlign: 'left' },
        {
          title: 'Available',
          field: 'starthour',
          mutator: (value, data) =>
            String(data.starthour).padStart(2, '0') +
            ':' +
            String(data.startmin).padStart(2, '0') +
            ' - ' +
            String(data.endhour).padStart(2, '0') +
            ':' +
            String(data.endmin).padStart(2, '0'),
          hozAlign: 'right',
          headerHozAlign: 'right',
        },
        {
          title: 'Status',
          field: 'status',
          formatter: status,
          width: 150,
          responsive: 0,
          hozAlign: 'right',
          headerHozAlign: 'right',
        },
      ],
      locale: true,
      langs: {
        en: {
          pagination: {
            first: 'First',
            first_title: 'First Page',
            last: 'Last',
            last_title: 'Last Page',
            prev: 'Prev',
            prev_title: 'Previous Page',
            next: 'Next',
            next_title: 'Next Page',
          },
          headerFilters: {
            default: 'filter column...',
          },
          columns: {
            id: 'Day',
            starthour: 'Available',
            status: 'Status',
            dayofweek: 'Day of Week',
          },
        },
        it: {
          columns: {
            id: 'Giorno',
            starthour: 'Di partenza',
            status: 'Stato',
            dayofweek: 'Giorno della settimana',
          },
        },
      },
    });
    menuavailabilityTable.on('rowMoved', function (row) {
      const rows = menuavailabilityTable.getRows();
      for (let i = 0; i < rows.length; i++) {
        menuavailabilityTable.updateData([
          { id: rows[i].getData().id, sequence: rows[i].getPosition() },
        ]);
        const mu = {
          menuavailability: {
            sequence: rows[i].getPosition(),
          },
        };
        fetch(rows[i].getData().url, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
          },
          body: JSON.stringify(mu),
        });
      }
    });
    menuavailabilityTable.on('rowSelectionChanged', function (data, rows) {
      if (data.length > 0) {
        document.getElementById('menuavailability-actions').disabled = false;
      } else {
        document.getElementById('menuavailability-actions').disabled = true;
      }
    });
    document.getElementById('activate-menuavailability').addEventListener('click', function () {
      const rows = menuavailabilityTable.getSelectedData();
      for (let i = 0; i < rows.length; i++) {
        menuavailabilityTable.updateData([{ id: rows[i].id, status: 'active' }]);
        const r = {
          menuavailability: {
            status: 'active',
          },
        };
        patch(rows[i].url, r);
      }
    });
    document.getElementById('deactivate-menuavailability').addEventListener('click', function () {
      const rows = menuavailabilityTable.getSelectedData();
      for (let i = 0; i < rows.length; i++) {
        menuavailabilityTable.updateData([{ id: rows[i].id, status: 'inactive' }]);
        const r = {
          menuavailability: {
            status: 'inactive',
          },
        };
        patch(rows[i].url, r);
      }
    });
  }
}
