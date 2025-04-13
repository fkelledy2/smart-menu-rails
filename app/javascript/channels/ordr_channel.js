import consumer from "./consumer"

consumer.subscriptions.create("OrdrChannel", {
  connected() {
    console.log( 'connected');
  },

  disconnected() {
    console.log( 'disconnected');
  },

  received(data) {
    console.log( 'received:'+JSON.stringify(data));
    if ($('#currentOrder').length) {
        let currentOrdrId = parseInt($('#currentOrder').text());
	    var updatedOrdr = JSON.parse(JSON.stringify(data));
        if( updatedOrdr.id == currentOrdrId ) {
            $("#orderUpdatedSpan").show();
        }
    }
//    if( data['status'] != 'closed' ) {
        location.reload();
//    }
    return true;
  }
});
