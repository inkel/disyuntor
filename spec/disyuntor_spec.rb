require "minitest/autorun"
require_relative "../lib/disyuntor"

describe Disyuntor do
  let(:circuit) { Disyuntor.new }

  describe "circuit closed" do
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

    it "can trigger an open state"
    it "cannot trigger a half-open state"
    it "can trigger a close state"
  end

  describe "circuit open" do
    it "should not increment failures counter"
    it "should call #on_circuit_open"
    it "should not call #trip block"
    it "should not change #opened_at"
    it "can trigger a half-open state"
    it "cannot trigger a close state"
    it "cannot trigger an open state"
  end

  describe "circuit half-open" do
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

    it "can trigger open state"
    it "can trigger close state"
    it "cannot trigger half-open state"
  end
end
