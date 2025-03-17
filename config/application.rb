# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# require 'dotenv/load'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'pycall'  # Add this to require PyCall

module CleoCourseScheduler
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Ensure PyCall uses the correct Python version
    PyCall.init('/usr/bin/python3') # Change this if needed (`which python3` in terminal)

    # Ensure pdfplumber is available
    begin
      PyCall.builtins.exec("import pdfplumber")
    rescue PyCall::PyError
      puts "Installing pdfplumber..."
      PyCall.builtins.exec("import pip; pip.main(['install', 'pdfplumber'])")
    end

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
