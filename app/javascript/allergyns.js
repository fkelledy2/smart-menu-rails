document.addEventListener("turbo:load", () => {
    if ($("#menusectionConfig").is(':visible')) {
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
          {title:"Description", field:"description", responsive:5},
          {title:"Symbol", field:"symbol", responsive:0, hozAlign:"right", headerHozAlign:"right" }
          ],
        });
    }
})