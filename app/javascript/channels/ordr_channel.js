import consumer from "./consumer"

consumer.subscriptions.create("OrdrChannel", {
  connected() {
    console.log("connected")
  },

  disconnected() {
    console.log("disconnected")
  },

  received(data) {
    console.log("received: "+JSON.strongify(data))
  }
});
