export function initAllergyns() {
  if ($('#restaurantTabs').length) {
    // Debounce utility to prevent rapid successive calls
    function debounce(func, wait) {
      let timeout;
      return function executedFunction(...args) {
        const later = () => {
          clearTimeout(timeout);
          func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
      };
    }
    function status(cell, formatterParams) {
      return cell.getRow().getData('data').status.toUpperCase();
    }
    // Allergyns
    function link(cell, formatterParams) {
      const id = cell.getValue();
      const name = cell.getRow();
      const rowData = cell.getRow().getData('data').name;
      return "<a class='link-dark' href='/allergyns/" + id + "/edit'>" + rowData + '</a>';
    }
    const allergynTableElement = document.getElementById('allergyn-table');
    if (!allergynTableElement) return; // Exit if element doesn't exist
    const restaurantId = allergynTableElement.getAttribute('data-bs-restaurant_id');
    const allergynTable = new Tabulator('#allergyn-table', {
      dataLoader: false,
      height: '400px', // Fixed height instead of 100%
      responsiveLayout: 'hide',
      initialSort: [{ column: 'sequence', dir: 'asc' }],
      layout: 'fitColumns',
      ajaxURL: '/restaurants/' + restaurantId + '/allergyns.json',
      movableRows: true,
      virtualDom: false, // Disable virtual DOM to prevent recursion issues
      renderVertical: 'basic', // Use basic rendering instead of virtual
      renderHorizontal: 'basic',
      columns: [
        {
          formatter: 'rowSelection',
          titleFormatter: 'rowSelection',
          width: 30,
          responsive: 0,
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
          responsive: 5,
          hozAlign: 'right',
          headerHozAlign: 'right',
          headerSort: false,
        },
        { title: 'Name', field: 'id', responsive: 0, formatter: link, hozAlign: 'left' },
        {
          title: 'Symbol',
          field: 'symbol',
          responsive: 1,
          hozAlign: 'right',
          headerHozAlign: 'right',
        },
        { title: 'Description', field: 'description', responsive: 5 },
        {
          title: 'Status',
          field: 'status',
          formatter: status,
          responsive: 0,
          minWidth: 100,
          hozAlign: 'right',
          headerHozAlign: 'right',
        },
      ],
      locale: true,
      langs: {
        it: {
          columns: {
            id: 'Nome', //replace the title of column name with the value "Name"
            symbol: 'Simbolo', //replace the title of column name with the value "Name"
            description: 'Descrizione', //replace the title of column name with the value "Name"
            status: 'Stato', //replace the title of column name with the value "Name"
          },
        },
        en: {
          columns: {
            id: 'Name', //replace the title of column name with the value "Name"
            symbol: 'Symbol', //replace the title of column name with the value "Name"
            description: 'Description', //replace the title of column name with the value "Name"
            status: 'Status', //replace the title of column name with the value "Name"
          },
        },
      },
    });
    // Debounced row move handler to prevent infinite recursion
    const debouncedRowMoved = debounce(function (row) {
      try {
        const rows = allergynTable.getRows();
        const updates = [];

        for (let i = 0; i < rows.length; i++) {
          const rowData = rows[i].getData();
          const newSequence = rows[i].getPosition();

          // Only update if sequence actually changed
          if (rowData.sequence !== newSequence) {
            updates.push({
              id: rowData.id,
              sequence: newSequence,
            });

            const mu = {
              allergyn: {
                sequence: newSequence,
                restaurant_id: restaurantId,
              },
            };

            fetch(rowData.url, {
              method: 'PATCH',
              headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
              },
              body: JSON.stringify(mu),
            }).catch((error) => {
              console.error('Error updating allergyn sequence:', error);
            });
          }
        }

        // Batch update data only once if there are changes
        if (updates.length > 0) {
          allergynTable.updateData(updates);
        }
      } catch (error) {
        console.error('Error in rowMoved handler:', error);
      }
    }, 300); // 300ms debounce

    allergynTable.on('rowMoved', debouncedRowMoved);
    allergynTable.on('rowSelectionChanged', function (data, rows) {
      if (data.length > 0) {
        document.getElementById('allergyn-actions').disabled = false;
      } else {
        document.getElementById('allergyn-actions').disabled = true;
      }
    });

    document.getElementById('activate-allergyn').addEventListener('click', function () {
      const rows = allergynTable.getSelectedData();
      const updates = [];

      for (let i = 0; i < rows.length; i++) {
        updates.push({ id: rows[i].id, status: 'active' });
        const r = {
          allergyn: {
            status: 'active',
          },
        };
        patch(rows[i].url, r);
      }

      // Batch update all status changes at once
      if (updates.length > 0) {
        allergynTable.updateData(updates);
      }
    });

    document.getElementById('deactivate-allergyn').addEventListener('click', function () {
      const rows = allergynTable.getSelectedData();
      const updates = [];

      for (let i = 0; i < rows.length; i++) {
        updates.push({ id: rows[i].id, status: 'inactive' });
        const r = {
          allergyn: {
            status: 'inactive',
          },
        };
        patch(rows[i].url, r);
      }

      // Batch update all status changes at once
      if (updates.length > 0) {
        allergynTable.updateData(updates);
      }
    });
  }
}
