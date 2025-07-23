document.addEventListener("turbo:load", () => {

  const tableElement = document.getElementById('dw-orders-mv-table');
  const loadingElement = document.getElementById('tabulator-loading');
  if (!tableElement || !loadingElement) return;

  let restaurantCurrencySymbol = '$';

  renderTable(tableElement);

  function renderTable(element) {
    const columns = [
      {title: "Order ID", field: "order_id", sorter: "number", frozen:true, widthGrow: 0},
      {title: "Country", field: "country", sorter: "string", responsive:4, hozAlign:"right", headerHozAlign:"right", widthGrow: 0},
      {title: "Restaurant", widthGrow:6, field: "restaurant_name", sorter: "string", responsive:1},
      {title: "Menu", field: "menu_name", sorter: "string", responsive:1, hozAlign:"right", headerHozAlign:"right", widthGrow: 1},
      {title: "Nett", field:"nett_amount", formatter:"money", hozAlign:"right", headerHozAlign:"right", responsive:0, widthGrow: 0,
        formatterParams:{
           decimal:".",
           thousand:",",
           symbol:restaurantCurrencySymbol,
           negativeSign:true,
           precision:2,
        }
      },      
      {title: "Tax", field:"tax_amount", formatter:"money", hozAlign:"right", headerHozAlign:"right", responsive:4, widthGrow: 0,
        formatterParams:{
           decimal:".",
           thousand:",",
           symbol:restaurantCurrencySymbol,
           negativeSign:true,
           precision:2,
        }
      },
      {title: "Tip", field:"tip_amount", formatter:"money", hozAlign:"right", headerHozAlign:"right", responsive:4, widthGrow: 0,
        formatterParams:{
           decimal:".",
           thousand:",",
           symbol:restaurantCurrencySymbol,
           negativeSign:true,
           precision:2,
        }
      },
      {title: "Cover", field:"covercharge_amount", formatter:"money", headerHozAlign:"right", hozAlign:"right", responsive:4, widthGrow: 0,
        formatterParams:{
           decimal:".",
           thousand:",",
           symbol:restaurantCurrencySymbol,
           negativeSign:true,
           precision:2,
        }
      },
      {title: "Gross", field:"gross_amount", formatter:"money", hozAlign:"right", headerHozAlign:"right", responsive:0, widthGrow: 0,
        formatterParams:{
           decimal:".",
           thousand:",",
           symbol:restaurantCurrencySymbol,
           negativeSign:true,
           precision:2,
        }
      },
      {title: "Employee ID", field: "employee_id", sorter: "number", hozAlign:"right", headerHozAlign:"right", responsive:3, widthGrow: 0},
      {title: "Table", field: "table_name", sorter: "string", hozAlign:"right", headerHozAlign:"right", responsive:4, widthGrow: 0},
      {title:"Paid At", field:"paid_at", formatter:"datetime", frozen:true, hozAlign:"right", headerHozAlign:"right", width: 180, formatterParams:{
        inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        outputFormat:"dd/MM/yyyy HH:mm",
        invalidPlaceholder:"(invalid date)"
      }},
      {title:"Ordered At", field:"ordered_at", frozen:true, hozAlign:"right", headerHozAlign:"right", formatter:"datetime", width: 180, formatterParams:{
        inputFormat:"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        outputFormat:"dd/MM/yyyy HH:mm",
        invalidPlaceholder:"(invalid date)"
      }}
    ];
    // Ensure the container allows horizontal scrolling
    element.style.overflowX = "auto";
    element.style.width = "100%";
    new Tabulator(element, {
      pagination:true,
      paginationSize:10,
      dataLoader: false,
      maxHeight:"100%",
      responsiveLayout:true,
      layout:"fitColumns",
      ajaxURL: tableElement.getAttribute('data-json-url'),
      initialSort:[
        {column:"ordered_at", dir:"desc"}
      ],
      columns: columns,
      movableColumns: true,
      virtualDomHoz: true,
    });
  }
});
