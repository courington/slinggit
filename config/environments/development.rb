SlinggitWebapp::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  PROD_ENV = false

  #  Our consumer key and secret for our twitter app (DEV)
  #config.twitter_consumer_key = 'uVUtXqE5xN5yVtZgLd5u3w'
  #config.twitter_consumer_secret = 'TmguQ0JOAs0a3ILREjvlhSEM2Igi5S4hF86cQdxtG0'

  # Prod credentials.  Only here right now for error testing.
   config.twitter_consumer_key = 'exOxe0rmGNEBBGsyW9nCA'
   config.twitter_consumer_secret = 'rwN7VmydrgRlRdb0kev1XxRi30YSpXHI7oXQEpPgUE'

  # @slinggit's authentication token and password, generated from the above consumer
  # key and secret.
  config.slinggit_client_atoken = '561831843-mHAqcKLJfFyCSQOXvlyH5fCvHRlRhRqMFDPNMS9h'
  config.slinggit_client_asecret = 'T7yvd3FfhpVJacLS6zjFO3yrXl8HDurhfXLq3AQL8'
end
