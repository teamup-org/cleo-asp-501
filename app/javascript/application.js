// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Import and start Rails UJS
import Rails from "@rails/ujs"
Rails.start()

// Import Bootstrap
import "bootstrap"

// Import all JavaScript files in the directory
//= require_tree .

