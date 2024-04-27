import consumer from "./consumer"

consumer.subscriptions.create("OrdrChannel", {
  connected() {
  },

  disconnected() {
  },

  received(data) {
    if ($('#currentOrder').length) {
        console.log("received: "+JSON.stringify(data))
        $("#orderUpdatedSpan").show();
    }
  }
});
