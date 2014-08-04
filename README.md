# Xirr

This is a simple gem to calculate XIRR on Bisection Method based on this gist http://puneinvestor.wordpress.com/2013/10/01/calculate-xirr-in-ruby-bisection-method/
and ont Finance gem written by 

## Installation

Add this line to your application's Gemfile:

    gem 'xirr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install xirr

## Usage


cf = Cashflow.new
cf << Transaction.new(1000, '2014-01-01'.to_time.utc)
cf << Transaction.new(1000, '2014-03-01'.to_time.utc)
cf << Transaction.new(-4000, '2014-06-01'.to_time.utc)
cf.xirr

## Contributing

1. Fork it ( https://github.com/[my-github-username]/xirr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
