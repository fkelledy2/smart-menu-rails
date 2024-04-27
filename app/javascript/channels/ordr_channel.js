import consumer from "./consumer"

consumer.subscriptions.create("OrdrChannel", {
  connected() {
  },

  disconnected() {
  },

  received(data) {
    if ($('#currentOrder').length) {
        let currentOrdrId = parseInt($('#currentOrder').text());
	    var updatedOrdr = JSON.parse(JSON.stringify(data));
        if( updatedOrdr.id == currentOrdrId ) {
            $("#orderUpdatedSpan").show();
        }
    }
  }
});
