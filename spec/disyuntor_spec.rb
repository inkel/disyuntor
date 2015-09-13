require "minitest/autorun"
require_relative "../lib/disyuntor"

describe Disyuntor do
  let(:circuit) { Disyuntor.new }

  describe :new do
    it "be closed by default" do
      assert circuit.closed?
      refute circuit.open?
      refute circuit.half_open?
    end

    it "should has no failures" do
      assert_equal 0, circuit.failures
    end

    it "should not report #opened_at" do
      refute circuit.opened_at
    end

    it "should set default circuit open fallback" do
      assert_raises(Disyuntor::CircuitOpenError) do
        circuit.on_circuit_open
      end
    end

    it "should override defaults" do
      circuit = Disyuntor.new(threshold: 20, timeout: 60) do
        fail RuntimeError
      end

      assert_equal 20, circuit.threshold
      assert_equal 60, circuit.timeout

      assert_raises(RuntimeError) do
        circuit.on_circuit_open
      end
    end
  end

  describe :open! do
    it "should set #opened_at" do
      Time.stub(:now, Time.mktime(1978, 7, 16)) do
        circuit.open!
      end

      assert_equal Time.mktime(1978, 7, 16).to_i, circuit.opened_at
    end
  end

  describe "circuit closed" do
    before do
      circuit.close!
    end

    describe "success" do
      it "should not increment failures counter" do
        failures = circuit.failures
        circuit.try{ true }

        assert_equal failures, circuit.failures
      end

      it "should not trip circuit" do
        circuit.try{ true }

        assert circuit.closed?
      end

      it "should return the block's value" do
        assert_equal 123, circuit.try{ 123 }
      end
    end

    describe "failure" do
      describe "threshold not reached" do
        it "should increment failures counter" do
          failures = circuit.failures
          circuit.try{ fail RuntimeError } rescue nil

          assert_equal failures.succ, circuit.failures
        end

        it "should raise the failure" do
          assert_raises(RuntimeError) do
            circuit.try{ fail RuntimeError }
          end

          assert_raises(ZeroDivisionError) do
            circuit.try{ 1 / 0 }
          end
        end
      end

      describe "threshold reached" do
        let(:circuit) { Disyuntor.new(threshold: 1) }

        before do
          circuit.try{ fail RuntimeError } rescue nil
          circuit.try{ fail RuntimeError } rescue nil
        end

        it "should stop incrementing failures counter" do
          failures = circuit.failures
          circuit.try{ fail RuntimeError } rescue nil

          assert_equal failures, circuit.failures
        end

        it "should call #on_circuit_open" do
          block_called = nil

          circuit.on_circuit_open do
            block_called = true
          end

          circuit.try{ fail RuntimeError }

          assert block_called
        end

        it "should trip the circuit" do
          assert circuit.open?
          refute circuit.closed?
          refute circuit.half_open?
        end
      end
    end

    it "can trigger an open state" do
      circuit.open!

      assert circuit.open?
      refute circuit.closed?
      refute circuit.half_open?
    end

    it "cannot trigger a half-open state" do
      assert_raises(MicroMachine::InvalidState) do
        circuit.half_open!
      end

      assert circuit.closed?
      refute circuit.half_open?
      refute circuit.open?
    end

    it "can trigger a close state" do
      circuit.close!

      assert circuit.closed?
      refute circuit.half_open?
      refute circuit.open?
    end
  end

  describe "circuit open" do
    before do
      circuit.open!
    end

    it "should not increment failures counter" do
      failures = circuit.failures

      circuit.try{ true } rescue nil

      assert_equal failures, circuit.failures

      circuit.try{ fail RuntimeError } rescue nil

      assert_equal failures, circuit.failures
    end

    it "should call #on_circuit_open" do
      assert_raises(Disyuntor::CircuitOpenError) do
        circuit.try{ true }
      end

      circuit.on_circuit_open do
        123
      end

      assert_equal 123, circuit.try{ true }
    end

    it "should not call #trip block" do
      block_called = nil
      circuit.try{ block_called = true } rescue nil
      refute block_called
    end

    it "should not change #opened_at" do
      opened_at = circuit.opened_at
      circuit.try{ true } rescue nil
      assert_equal opened_at, circuit.opened_at
    end

    it "can trigger a half-open state" do
      circuit.half_open!

      assert circuit.half_open?
      refute circuit.open?
      refute circuit.closed?
    end

    it "cannot trigger a close state" do
      assert_raises(MicroMachine::InvalidState) do
        circuit.close!
      end

      assert circuit.open?
      refute circuit.closed?
      refute circuit.half_open?
    end

    it "cannot trigger an open state" do
      assert_raises(MicroMachine::InvalidState) do
        circuit.open!
      end

      assert circuit.open?
      refute circuit.closed?
      refute circuit.half_open?
    end
  end

  describe "circuit half-open" do
    before do
      circuit.open!
      circuit.half_open!
    end

    it "should call #try block" do
      block_called = nil
      circuit.try do
        block_called = true
        fail RuntimeError
      end rescue nil

      assert block_called

      circuit.half_open!

      block_called = nil
      circuit.try { block_called = true }
      assert block_called
    end

    describe "on failure" do
      before do
        circuit.try{ fail RuntimeError } rescue nil
      end

      it "should trip circuit" do
        assert circuit.open?
      end
    end

    describe "on success" do
      before do
        @ret = circuit.try { [true, 123] }
      end

      it "should reset circuit" do
        assert circuit.closed?
      end

      it "should cleanup #opened_at" do
        refute circuit.opened_at
      end

      it "should cleanup #failures" do
        assert_equal 0, circuit.failures
      end

      it "should return #try block return value" do
        assert_equal [true, 123], @ret
      end
    end

    it "can trigger open state" do
      circuit.open!

      assert circuit.open?
      refute circuit.half_open?
      refute circuit.closed?
    end

    it "can trigger close state" do
      circuit.close!

      assert circuit.closed?
      refute circuit.half_open?
      refute circuit.open?
    end

    it "cannot trigger half-open state" do
      assert_raises(MicroMachine::InvalidState) do
        circuit.half_open!
      end

      assert circuit.half_open?
      refute circuit.closed?
      refute circuit.open?
    end
  end
end
