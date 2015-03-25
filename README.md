# Reliable

A ruby gem to reliably retry methods and blocks in a reusable, customizable, clean way.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reliable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reliable

## Usage

```ruby
Reliable::Tryer.after_call = -> value:, error:, tries: {
  puts "#{tries}: value=#{value}, error=#{error.class.name}(#{error})"
}

class Test
  extend Reliable

  class FooError < StandardError; end

  def foo
    raise FooError, 'message' if rand < 0.8
    "successful result"
  end

  retries :foo, up_to: 3.times, on: FooError
end

# Test.new.foo
#1: value=, error=Test::FooError(message)
#Retrying on error: Test::FooError: message
#2: value=, error=Test::FooError(message)
#Retrying on error: Test::FooError: message
#3: value=successful result, error=NilClass()
#=> "successful result"
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/reliable/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
