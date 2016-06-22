# Simple Circuit Breaker Pattern in Ruby

[![Join the chat at https://gitter.im/inkel/disyuntor](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/inkel/disyuntor?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) ![build status on master](https://travis-ci.org/inkel/disyuntor.svg?branch=master)

This gem implements a very simple class to deal with the Circuit Breaker Pattern as described by [Michael T. Nygard](http://www.michaelnygard.com/) in his amazing and highly recommended [Release It! - Design and Deploy Production-Ready Software](http://www.amazon.com/Release-It-Production-Ready-Pragmatic-Programmers/dp/0978739213).

## Usage

```ruby
require "disyuntor"

# Trip circuit after 10 errors
# Wait 5 seconds before trying again
disyuntor = Disyuntor.new(threshold: 10, timeout: 5)

res = disyuntor.try do
  # …your potentially failing operation…
end
```

A _Disyuntor_, or circuit breaker, has two (and a half) possible states:

* `#closed?` for when the protection hasn't detected any issues and your code is allowed to run;
* `#open?` for when the protection has reached a `threshold` of issues and your code won't be allowed to run.

The third, or rather second and a half state, is for when the circuit was open and `timeout` seconds passed. In this state your code is allowed to run **just once**. If it works without raising any new failure, then the circuit will automatically close itself until, otherwise it will remain in an open state for a new `timeout` interval in seconds.

## Custom actions when circuit is open

By default, when the circuit is open, `Disyuntor#try` will fail with a `Disyuntor::CircuitOpenError`. This behavior can be changed by passing a `Proc` in the `on_circuit_open` option or method.

Every time the circuit is open, the `#on_circuit_open` method is called, passing the circuit as its argument. This allows customizing the failure mode of your circuit:

```ruby
disyuntor = Disyuntor.new(threshold: 3, timeout: 5)

disyuntor.on_circuit_open do |c|
  puts "Ooops, can't execute circuit"
end
```

The value of the block will be returned as the value of `Disyuntor#try` when it fails.
