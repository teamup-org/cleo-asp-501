// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Import and start Rails UJS
import Rails from "@rails/ujs"
Rails.start()

// Import Bootstrap
import "bootstrap"

// Initialize Stimulus controllers
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

// Import all JavaScript files in the directory
//= require_tree .

