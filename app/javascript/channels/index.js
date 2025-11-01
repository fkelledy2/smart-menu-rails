// Import all the channels to be used by Action Cable
import './ordr_channel';

// Create and expose Action Cable consumer globally for non-module scripts
import { createConsumer } from '@rails/actioncable';

window.App = window.App || {};
window.App.cable = createConsumer();
