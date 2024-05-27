document.addEventListener("turbo:load", () => {
    if ($("#allergyn-table").is(':visible')) {
        // Allergyns
        var allergynTable = new Tabulator("#allergyn-table", {
          dataLoader: false,
          maxHeight:"100%",
          responsiveLayout:true,
          layout:"fitDataStretch",
          ajaxURL: '/allergyns.json',
          columns: [
          {
            title:"Name", field:"id", responsive:0, formatter:"link", formatterParams: {
                labelField:"name",
                urlPrefix:"/allergyns/",
            }
          },
          {title:"Symbol", field:"symbol", width:150, responsive:0}
          ],
        });
    }
})