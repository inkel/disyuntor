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
    @cb = Disyuntor.new(threshold: @threshold, timeout: @timeout)
  end

  def test_initialize_closed
    assert @cb.closed?
  end

  def test_initialize_without_failures
    assert_equal 0, @cb.failures
  end

  def test_closed_circuit_returns_block_value
    assert_equal 42, @cb.try { 42 }
  end

  def test_closed_circuit_do_not_count_failures_on_success
    @cb.try { true }
    assert_equal 0, @cb.failures
  end

  def test_reset_failures_counter_on_closed_circuit_success
    begin
      @cb.try { fail CustomRuntimeError }
    rescue CustomRuntimeError
    end

    assert_equal 1, @cb.failures

    @cb.try { true }

    assert_equal 0, @cb.failures
  end

  def test_open_circuit_after_threshold_failures
    @cb.threshold.times do
      begin
        @cb.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @cb.closed?
  end

  def test_open_circuit_raises_default_error
    @cb.threshold.times do
      begin
        @cb.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    assert_raises(Disyuntor::CircuitOpenError) do
      @cb.try { fail CustomRuntimeError }
    end
  end

  def test_override_on_circuit_open
    @cb.on_circuit_open { 42 }

    @cb.threshold.times do
      begin
        @cb.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    assert_equal 42, @cb.try { fail CustomRuntimeError }
  end

  def test_count_failures
    assert_equal 0, @cb.failures

    @cb.threshold.times do
      begin
        @cb.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    assert_equal @threshold, @cb.failures
  end

  def test_do_not_count_failures_when_open
    @cb.threshold.times do
      begin
        @cb.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    begin
      @cb.try { fail CustomRuntimeError }
    rescue Disyuntor::CircuitOpenError
    end

    assert_equal @threshold, @cb.failures
  end

  def test_close_after_timeout_if_success
    @cb.threshold.times do
      begin
        @cb.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @cb.closed?

    Time.stub(:now, Time.at(Time.now.to_i + @timeout + 1)) do
      assert_equal 42, @cb.try { 42 }
    end

    assert @cb.closed?
  end

  def test_reopen_after_timeout_if_fails
    @cb.threshold.times do
      begin
        @cb.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @cb.closed?

    Time.stub(:now, Time.at(Time.now.to_i + @timeout + 1)) do
      assert_raises(CustomRuntimeError) do
        @cb.try { fail CustomRuntimeError }
      end
    end

    refute @cb.closed?
  end

  def test_count_failure_after_timeout_if_fails
    @cb.threshold.times do
      begin
        @cb.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @cb.closed?

    Time.stub(:now, Time.at(Time.now.to_i + @timeout + 1)) do
      assert_raises(CustomRuntimeError) do
        @cb.try { fail CustomRuntimeError }
      end
    end

    assert_equal @threshold.next, @cb.failures
  end

  def test_close_after_timeout_if_succeeds
    @cb.threshold.times do
      begin
        @cb.try { fail CustomRuntimeError }
      rescue CustomRuntimeError
      end
    end

    refute @cb.closed?

    Time.stub(:now, Time.at(Time.now.to_i + @timeout + 1)) do
      assert_equal 42, @cb.try { 42 }
    end

    assert @cb.closed?
  end
end
