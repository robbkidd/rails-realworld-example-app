# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'opentelemetry/sdk'
require 'opentelemetry/exporters/jaeger'

# Configure the sdk with default export and context propagation formats
# see SDK#configure for customizing the setup
OpenTelemetry::SDK.configure do |c|
  c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
          OpenTelemetry::Exporters::Jaeger::Exporter.new(
              service_name: 'realworld-rails', host: 'otel-collector', port: 6831
          )
      )
  )
end

# To start a trace you need to get a Tracer from the TracerProvider
tracer = OpenTelemetry.tracer_provider.tracer('realworld', '0.1.0')

# create a span
tracer.in_span('foo') do |span|
  # set an attribute
  span.set_attribute('platform', 'osx')
  # add an event
  span.add_event(name: 'event in bar') # this isn't propagating properly
  # create bar as child of foo
  tracer.in_span('bar') do |child_span|
    # inspect the spanc
    # pp child_span
  end
end

# pp tracer.inspect

module Conduit
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.api_only = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.middleware.insert_before 0, Rack::Cors, debug: true, logger: (-> { Rails.logger }) do
      allow do
        origins Rails.application.secrets[:client_root_url]

        resource '/api/*',
                 headers: :any,
                 methods: %i[get post delete put patch options head]
      end
    end
  end
end
