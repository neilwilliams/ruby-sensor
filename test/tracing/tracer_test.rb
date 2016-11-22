require 'test_helper'

class TracerTest < Minitest::Test
  def test_that_it_has_a_valid_tracer
    refute_nil ::Instana.tracer
    assert ::Instana.tracer.is_a?(::Instana::Tracer)
  end

  def test_basic_trace_block
    ::Instana.tracer.start_or_continue_trace(:test_trace, {:one => 1}) do
      sleep 0.5
    end

    traces = ::Instana.processor.queued_traces
    assert_equal 1, traces.count
    t = traces.first
    assert_equal 1, t.spans.size
    assert t.valid?

    first_span = t.spans.first
    assert_equal :test_trace, first_span[:n]
    assert_equal :ruby, first_span[:ta]
    assert first_span.key?(:data)
    assert_equal 1, first_span[:data][:one]
    assert first_span.key?(:f)
    assert first_span[:f].key?(:e)
    assert first_span[:f].key?(:h)
    assert_equal ::Instana.agent.agent_uuid, first_span[:f][:h]
  end

  def test_errors_are_properly_propogated
    exception_raised = false
    begin
      ::Instana.tracer.start_or_continue_trace(:test_trace, {:one => 1}) do
        raise Exception.new('Error in block - this should continue to propogate outside of tracing')
      end
    rescue Exception
      exception_raised = true
    end

    assert exception_raised

    traces = ::Instana.processor.queued_traces
    assert_equal 1, traces.count
    t = traces.first
    assert_equal 1, t.spans.size
    assert t.valid?

    first_span = t.spans.first
    assert_equal :test_trace, first_span[:n]
    assert_equal :ruby, first_span[:ta]
    assert first_span.key?(:data)
    assert_equal 1, first_span[:data][:one]
    assert first_span.key?(:f)
    assert first_span[:f].key?(:e)
    assert first_span[:f].key?(:h)
    assert_equal ::Instana.agent.agent_uuid, first_span[:f][:h]
    assert t.has_error?
  end

  def test_complex_trace_block
    ::Instana.tracer.start_or_continue_trace(:test_trace, {:one => 1}) do
      sleep 0.2
      ::Instana.tracer.trace(:sub_block, {:sub_two => 2}) do
        sleep 0.2
      end
    end

    traces = ::Instana.processor.queued_traces
    assert_equal 1, traces.count
    t = traces.first
    assert_equal 2, t.spans.size
    assert t.valid?
  end

  def test_basic_low_level_tracing
    ::Instana.tracer.log_start_or_continue(:test_trace, {:one => 1})
    ::Instana.tracer.log_info({:info_logged => 1})
    ::Instana.tracer.log_end(:test_trace, {:close_one => 1})

    traces = ::Instana.processor.queued_traces
    assert_equal 1, traces.count
    t = traces.first
    assert_equal 1, t.spans.size
    assert t.valid?
  end

  def test_complex_low_level_tracing
    ::Instana.tracer.log_start_or_continue(:test_trace, {:one => 1})
    ::Instana.tracer.log_info({:info_logged => 1})

    ::Instana.tracer.log_entry(:sub_task)
    ::Instana.tracer.log_info({:sub_task_info => 1})
    ::Instana.tracer.log_exit(:sub_task, {:sub_task_exit_info => 1})

    ::Instana.tracer.log_end(:test_trace, {:close_one => 1})

    traces = ::Instana.processor.queued_traces
    assert_equal 1, traces.count

    t = traces.first
    assert_equal 2, t.spans.size
    assert t.valid?

    first_span = t.spans.first
    assert_equal :test_trace, first_span[:n]
    assert_equal :ruby, first_span[:ta]
    assert first_span.key?(:data)
    assert_equal 1, first_span[:data][:one]
    assert first_span.key?(:f)
    assert first_span[:f].key?(:e)
    assert first_span[:f].key?(:h)
    assert_equal ::Instana.agent.agent_uuid, first_span[:f][:h]
  end

  def test_block_tracing_error_capture
    exception_raised = false
    begin
      ::Instana.tracer.start_or_continue_trace(:test_trace, {:one => 1}) do
        raise Exception.new("Block exception test error")
      end
    rescue Exception
      exception_raised = true
    end

    assert exception_raised

    traces = ::Instana.processor.queued_traces
    assert_equal 1, traces.count

    t = traces.first
    assert_equal 1, t.spans.size
    assert t.valid?
    assert t.has_error?
  end

  def test_low_level_error_logging
    ::Instana.tracer.log_start_or_continue(:test_trace, {:one => 1})
    ::Instana.tracer.log_info({:info_logged => 1})
    ::Instana.tracer.log_error(Exception.new("Low level tracing api error"))
    ::Instana.tracer.log_end(:test_trace, {:close_one => 1})

    traces = ::Instana.processor.queued_traces
    assert_equal 1, traces.count

    t = traces.first
    assert_equal 1, t.spans.size
    assert t.valid?
    assert t.has_error?
  end

  def test_instana_headers_in_response
    ::Instana.tracer.start_or_continue_trace(:test_trace, {:one => 1}) do
      sleep 0.5
    end

    traces = ::Instana.processor.queued_traces
    assert_equal 1, traces.count
    t = traces.first
    assert_equal 1, t.spans.size
    assert t.valid?

    first_span = t.spans.first
    assert_equal :test_trace, first_span[:n]
    assert_equal :ruby, first_span[:ta]
    assert first_span.key?(:data)
    assert_equal 1, first_span[:data][:one]
    assert first_span.key?(:f)
    assert first_span[:f].key?(:e)
    assert first_span[:f].key?(:h)
    assert_equal ::Instana.agent.agent_uuid, first_span[:f][:h]
  end


end
