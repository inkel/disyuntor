require "micromachine"

class Disyuntor
  CircuitOpenError = Class.new(RuntimeError)

  DEFAULTS = {
    threshold: 5,
    timeout:   10,
    # callbacks
    on_circuit_open: Proc.new { fail CircuitOpenError }
  }.freeze

  attr_reader :options, :failures, :last_open

  def initialize(options={})
    @options   = DEFAULTS.merge(options)
    @failures  = 0
    @last_open = nil

    @fsm = MicroMachine.new(:closed)

    @fsm.when(:trip,  :closed    => :open,   :half_open => :open)
    @fsm.when(:reset, :half_open => :closed, :closed    => :closed)
    @fsm.when(:try,   :open      => :half_open)

    @fsm.on(:open)  do
      @last_open = Time.now.to_i
    end

    @fsm.on(:closed) do
      @last_open = nil
      @failures  = 0
    end
  end

  def on_circuit_open(&block)
    if block_given?
      @options[:on_circuit_open] = block
    else
      @options[:on_circuit_open].(self)
    end
  end

  def reset!
    @fsm.trigger!(:reset)
  end

  def trip!
    @fsm.trigger!(:trip)
  end

  def state
    @fsm.state
  end

  def closed?
    state == :closed
  end

  def open?
    state == :open
  end

  def timed_out?
    return false if closed?

    Time.now.to_i > (@last_open + @options[:timeout])
  end

  def try(&block)
    if closed?
      begin
        yield.tap do
          reset!
        end
      rescue
        @failures += 1
        trip! if @failures > @options[:threshold]
        on_circuit_open
      end
    elsif open?
      if timed_out?
        try_reset(&block)
      else
        on_circuit_open
      end
    end
  end

  def try_reset(&block)
    @fsm.trigger!(:try)

    begin
      yield.tap do
        reset!
      end
    rescue
      trip!
      on_circuit_open
    end
  end
end
