require "minitest/autorun"
require_relative "../lib/disyuntor"

describe Disyuntor do
  let(:circuit) { Disyuntor.new }

  describe "circuit closed" do
    before do
      circuit.close!
    end

    describe "success" do
      it "should call reset"
      it "should not increment failures counter"
      it "should not trip circuit"
      it "should return the block's value"
    end

    describe "failure" do
      describe "threshold not reached" do
        it "should increment failures counter"
        it "should raise the failure"
      end

      describe "threshold reached" do
        it "should stop incrementing failures counter"
        it "should call #on_circuit_open"
        it "should assign #opened_at"
        it "should trip the circuit"
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

    it "should not increment failures counter"
    it "should call #on_circuit_open"
    it "should not call #trip block"
    it "should not change #opened_at"

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

    it "should call #try block"

    describe "on failure" do
      it "should trip circuit"
      it "should update #opened_at"
    end

    describe "on success" do
      it "should reset circuit"
      it "should cleanup #opened_at"
      it "should cleanup #failures"
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
