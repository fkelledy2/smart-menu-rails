import consumer from "./consumer"

consumer.subscriptions.create("OrdrChannel", {
  connected() {
  },

  disconnected() {
  },

  received(data) {
    if ($('#currentOrder').length) {
        let currentOrdrId = parseInt($('#currentOrder').text());
	    var updatedOrdr = JSON.parse(data);
        if( updatedOrdr.id == currentOrdrId ) {
            console.log( 'updatedOrdr.id: '+updatedOrdr.id +' matches currentOrdrId:'+currentOrdrId);
            $("#orderUpdatedSpan").show();
        } else {
            console.log( 'updatedOrdr.id: '+updatedOrdr.id +' does not match currentOrdrId:'+currentOrdrId);
        }
    }
  }
});
