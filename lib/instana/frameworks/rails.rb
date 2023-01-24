# (c) Copyright IBM Corp. 2021
# (c) Copyright Instana Inc. 2016

if ::Rails::VERSION::MAJOR < 3
  ::Rails.configuration.after_initialize do
    if ::Instana.config[:tracing][:enabled]
      ::Instana.logger.debug "Instrumenting Rack"
      ::Rails.configuration.middleware.insert 0, ::Instana::Rack
    else
      ::Instana.logger.info "Rack: Tracing disabled via config.  Not enabling middleware."
    end
  end
else
  module ::Instana
    class Railtie < ::Rails::Railtie
      initializer 'instana.rack' do |app|
        # Configure the Instrumented Logger
        if ::Instana.config[:logging][:enabled] && !ENV.key?('INSTANA_TEST')
          # This code causes a stack level too deep when using the TaggedLogging formatter
          # activesupport-7.0.3.1/lib/active_support/tagged_logging.rb:105:in `block (2 levels) in broadcast_to': stack level too deep (SystemStackError)
	        # from activesupport-7.0.3.1/lib/active_support/tagged_logging.rb:105:in `block (2 levels) in broadcast_to'
          
          # logger = ::Instana::InstrumentedLogger.new('/dev/null')
          # Rails.logger.extend(ActiveSupport::Logger.broadcast(logger))

          # reverting to how it used to work...
          ::Instana.logger = Rails.logger
        end

        if ::Instana.config[:tracing][:enabled]
          ::Instana.logger.debug "Instrumenting Rack"
          app.config.middleware.insert 0, ::Instana::Rack
        else
          ::Instana.logger.info "Rack: Tracing disabled via config.  Not enabling middleware."
        end
      end
    end
  end
end
