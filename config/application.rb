# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# require 'dotenv/load'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'pycall'

module CleoCourseScheduler
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Ensure PyCall uses the correct Python version
    # python_path = `which python3`.strip
    # python_path = '/usr/bin/python3' if python_path.empty?

    PyCall.init('/usr/bin/python3') # Change this if needed (`which python3` in terminal)

    # Ensure pdfplumber is available
    begin
      PyCall.builtins.eval("import pdfplumber")
    rescue StandardError => e
      puts "Error importing pdfplumber: #{e.message}"
      puts "Attempting to install pdfplumber..."
      begin
        PyCall.builtins.eval("import pip; pip.main(['install', 'pdfplumber'])")
      rescue StandardError => install_error
        puts "Failed to install pdfplumber: #{install_error.message}"
      end
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
