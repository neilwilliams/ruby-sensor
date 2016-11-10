
require 'logger'
require "instana/version"
require "instana/util"

module Instana
  class << self
    attr_accessor :agent
    attr_accessor :collectors
    attr_accessor :tracer
    attr_accessor :processor
    attr_accessor :config
    attr_accessor :logger
    attr_accessor :pid

    ##
    # start
    #
    # Initialize the Instana language agent
    #
    def start
      @agent  = ::Instana::Agent.new
      @tracer = ::Instana::Tracer.new
      @processor = ::Instana::Processor.new
      @collectors = []
      @logger = ::Logger.new(STDOUT)
      @logger.info "Stan is on the scene.  Starting Instana instrumentation."

      # Store the current pid so we can detect a potential fork
      # later on
      @pid = ::Process.pid
    end

    def pid_change?
      @pid != ::Process.pid
    end
  end
end


require "instana/config"
require "instana/agent"
require "instana/tracing/tracer"
require "instana/tracing/processor"

::Instana.start

require "instana/collectors"

::Instana.agent.start
