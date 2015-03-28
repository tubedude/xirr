# Xirr
[![Build Status](https://travis-ci.org/tubedude/xirr.svg)](https://travis-ci.org/tubedude/xirr)[![Coverage Status](https://coveralls.io/repos/tubedude/xirr/badge.svg?branch=master)](https://coveralls.io/r/tubedude/xirr?branch=master)[![Code Climate](https://codeclimate.com/github/tubedude/xirr/badges/gpa.svg)](https://codeclimate.com/github/tubedude/xirr)[![Dependency Status](https://gemnasium.com/tubedude/xirr.svg)](https://gemnasium.com/tubedude/xirr)


This is a gem to calculate XIRR on Bisection Method or Newton Method.

## Installation

Add this line to your application's Gemfile:

    gem 'xirr'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install xirr

## Usage


    include Xirr
    
    cf = Cashflow.new
    cf << Transaction.new(-1000,  date: '2014-01-01'.to_date)
    cf << Transaction.new(-2000,  date: '2014-03-01'.to_date)
    cf << Transaction.new( 4500, date: '2015-12-01'.to_date)
    cf.xirr
    # 0.25159694345042327 # [BigDecimal]

    flow = []
    flow << Transaction.new(-1000,  date: '2014-01-01'.to_date)
    flow << Transaction.new(-2000,  date: '2014-03-01'.to_date)
    flow << Transaction.new( 4500, date: '2015-12-01'.to_date)

    cf = Cashflow.new flow: flow
    cf.xirr


## Configuration

    # intializer/xirr.rb
    
    Xirr.configure do |config|
      config.eps = '1.0e-12'
      config.days_in_year = 365.25
    end


## Documentation

http://rubydoc.info/github/tubedude/xirr/master/frames

## Thanks

http://puneinvestor.wordpress.com/2013/10/01/calculate-xirr-in-ruby-bisection-method/
https://github.com/wkranec/finance

## Contributing

1. Fork it ( https://github.com/tubedude/xirr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
