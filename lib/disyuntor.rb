class Disyuntor
  CircuitOpenError = Class.new(RuntimeError)

  attr_reader :failures, :threshold, :timeout

  def initialize(threshold:, timeout:)
    @threshold = threshold
    @timeout   = timeout

    on_circuit_open { fail CircuitOpenError }

    close!
  end

  def try(&block)
    case
    when closed?    then circuit_closed(&block)
    when half_open? then circuit_half_open(&block)
    when open?      then circuit_open
    end
  end

  def on_circuit_open(&block)
    raise ArgumentError, "Must pass a block" unless block_given?
    @on_circuit_open = block
  end

  def closed?() state == :closed end

  private

  attr_reader :opened_at, :state

  def close!
    @opened_at = nil
    @failures  = 0
    @state     = :closed
  end

  def open!
    @opened_at = Time.now.to_i
    @state     = :open
  end

  def open?() state == :open end

  def half_open?
    open? && timed_out?
  end

  def timed_out?
    open? && Time.now.to_i > next_timeout_at
  end

  def next_timeout_at
    opened_at + timeout
  end

  def increment_failures!
    @failures += 1
  end

  def circuit_closed(&block)
    ret = block.call
  rescue
    open! if increment_failures! >= threshold
    raise
  else
    close!
    ret
  end

  alias_method :circuit_half_open, :circuit_closed

  def circuit_open
    @on_circuit_open.call(self)
  end
end
