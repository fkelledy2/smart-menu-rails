// This file is used by the Stimulus auto-loader to load all Stimulus controllers in the app

// Configure Stimulus development experience
const application = Application.start()
const context = require.context("../controllers", true, /\.js$/)
application.load(definitionsFromContext(context))
