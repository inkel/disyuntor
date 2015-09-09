# Simple Circuit Breaker Pattern in Ruby

[![Join the chat at https://gitter.im/inkel/disyuntor](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/inkel/disyuntor?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This gem implements a very simple class to deal with the Circuit Breaker Pattern as described by [Michael T. Nygard](http://www.michaelnygard.com/) in his amazing and highly recommended [Release It! - Design and Deploy Production-Ready Software](http://www.amazon.com/Release-It-Production-Ready-Pragmatic-Programmers/dp/0978739213).

## Usage

```
require "disyuntor"

options = {
  # Trip circuit after 10 errors
  threshold: 10,
  # Wait 5 seconds before trying again
  timeout: 5
}

cb = Disyuntor.new(threshold: 10)

res = cb.try do
  # …your potentially failing operation…
end
```

By default, when the circuit is open, `Disyuntor#try` will fail with a `Disyuntor::CircuitOpenError`. This behavior can be changed by passing a `Proc` in the `on_circuit_open` option or method.

If you want to use it as a [`Rack`](https://github.com/rack/rack) middleware, add the following in your `config.ru`:

```
require "rack/disyuntor"

use Rack::Disyuntor, threshold: 10, timeout: 5
```

This will start responding with `[503, { "Content-Type" => "text/plain", ["Service Unavailable"]]` when the circuit is open.

## Custom actions when circuit is open

Every time the circuit is open, the `#on_circuit_open` method is called, passing the circuit as its argument. This allows customizing the failure mode of your circuit:

```ruby
circuit = Disyuntor.new(threshold: 3, timeout: 5)

circuit.on_circuit_open do |c|
  "Circuit was open at #{c.last_open}"
end
```

The value of the block will be returned as the value of `Disyuntor#try` when it fails.