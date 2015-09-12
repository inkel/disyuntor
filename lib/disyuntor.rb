require "micromachine"

class Disyuntor
  CircuitOpenError = Class.new(RuntimeError)

  attr_reader :options, :failures, :opened_at, :threshold, :timeout

  def initialize(threshold: 5, timeout: 10, &block)
    @threshold = threshold
    @timeout   = timeout

    @on_circuit_open = if block_given?
                         block
                       else
                         Proc.new{ fail CircuitOpenError }
                       end

    reset!
  end

  def states
    @states ||= MicroMachine.new(:closed).tap do |fsm|
      fsm.when(:trip,  :half_open => :open,   :closed => :open)
      fsm.when(:reset, :half_open => :closed, :closed => :closed)
      fsm.when(:try,   :open      => :half_open)

      fsm.on(:open) do
        @opened_at = Time.now.to_i
      end

      fsm.on(:closed) do
        @opened_at = nil
        @failures  = 0
      end
    end
  end

  def on_circuit_open(&block)
    if block_given?
      @on_circuit_open = block
    else
      @on_circuit_open.(self)
    end
  end

  def reset!
    states.trigger!(:reset)
  end

  def trip!
    states.trigger!(:trip)
  end

  def try!
    states.trigger!(:try)
  end

  def state
    states.state
  end

  def closed?
    state == :closed
  end

  def open?
    state == :open
  end

  def half_open?
    state == :half_open
  end

  def timed_out?
    return false if closed?

    Time.now.to_i > (@opened_at + @timeout)
  end

  def try(&block)
    try! if timed_out?

    case
    when closed?    then on_circuit_closed(&block)
    when half_open? then on_circuit_half_open(&block)
    when open?      then on_circuit_open
    else
      fail RuntimeError, "Invalid state! #{state}"
    end
  end

  def on_circuit_closed(&block)
    block.call
  rescue
    @failures += 1
    trip! if @failures > @threshold
    raise
  else
    reset!
  end

  def on_circuit_half_open(&block)
    block.call
  rescue
    trip!
    raise
  else
    reset!
  end
end
