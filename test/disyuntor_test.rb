if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/spec/"
    add_filter "/.gs/"
  end
end

require "minitest/autorun"
require_relative "../lib/disyuntor"

class DisyuntorTest < Minitest::Test
  CustomRuntimeError = Class.new(RuntimeError)

  def test_initialize_without_defaults
    assert_raises(ArgumentError) { Disyuntor.new }
  end

  def test_initialize_requires_timeout
    assert_raises(ArgumentError) do
      Disyuntor.new(threshold: 1)
    end
  end

  def test_initialize_requires_threshold
    assert_raises(ArgumentError) do
      Disyuntor.new(timeout: 1)
    end
  end

  def setup
    @threshold = 3
    @timeout   = 5
    @disyuntor = Disyuntor.new(threshold: @threshold, timeout: @timeout)
  end

  def test_initialize_closed
    assert @disyuntor.closed?
  end

  def test_initialize_without_failures
    assert_equal 0, @disyuntor.failures
  end

  def test_closed_circuit_returns_block_value
    assert_equal 42, @disyuntor.try { 42 }
  end

  def test_closed_circuit_do_not_count_failures_on_success
    @disyuntor.try { true }
    assert_equal 0, @disyuntor.failures
  end

  def test_reset_failures_counter_on_closed_circuit_success
    begin
      @disyuntor.try { fail CustomRuntimeError }
    rescue CustomRuntimeError
    end

    assert_equal 1, @disyuntor.failures

    @disyuntor.try { true }

    assert_equal 0, @disyuntor.failures
  end

  def test_open_circuit_after_threshold_failures
    @disyuntor.threshold.times do
      begin
        @disyuntor.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @disyuntor.closed?
  end

  def test_open_circuit_raises_default_error
    @disyuntor.threshold.times do
      begin
        @disyuntor.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    assert_raises(Disyuntor::CircuitOpenError) do
      @disyuntor.try { fail CustomRuntimeError }
    end
  end

  def test_override_on_circuit_open
    @disyuntor.on_circuit_open { 42 }

    @disyuntor.threshold.times do
      begin
        @disyuntor.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    assert_equal 42, @disyuntor.try { fail CustomRuntimeError }
  end

  def test_count_failures
    assert_equal 0, @disyuntor.failures

    @disyuntor.threshold.times do
      begin
        @disyuntor.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    assert_equal @threshold, @disyuntor.failures
  end

  def test_do_not_count_failures_when_open
    @disyuntor.threshold.times do
      begin
        @disyuntor.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    begin
      @disyuntor.try { fail CustomRuntimeError }
    rescue Disyuntor::CircuitOpenError
    end

    assert_equal @threshold, @disyuntor.failures
  end

  def test_close_after_timeout_if_success
    @disyuntor.threshold.times do
      begin
        @disyuntor.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @disyuntor.closed?

    Time.stub(:now, Time.at(Time.now.to_i + @timeout + 1)) do
      assert_equal 42, @disyuntor.try { 42 }
    end

    assert @disyuntor.closed?
  end

  def test_reopen_after_timeout_if_fails
    @disyuntor.threshold.times do
      begin
        @disyuntor.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @disyuntor.closed?

    Time.stub(:now, Time.at(Time.now.to_i + @timeout + 1)) do
      assert_raises(CustomRuntimeError) do
        @disyuntor.try { fail CustomRuntimeError }
      end
    end

    refute @disyuntor.closed?
  end

  def test_count_failure_after_timeout_if_fails
    @disyuntor.threshold.times do
      begin
        @disyuntor.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @disyuntor.closed?

    Time.stub(:now, Time.at(Time.now.to_i + @timeout + 1)) do
      assert_raises(CustomRuntimeError) do
        @disyuntor.try { fail CustomRuntimeError }
      end
    end

    assert_equal @threshold.next, @disyuntor.failures
  end

  def test_close_after_timeout_if_succeeds
    @disyuntor.threshold.times do
      begin
        @disyuntor.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @disyuntor.closed?

    Time.stub(:now, Time.at(Time.now.to_i + @timeout + 1)) do
      assert_equal 42, @disyuntor.try { 42 }
    end

    assert @disyuntor.closed?
  end
end
