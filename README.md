# Xirr
[![Build Status](https://travis-ci.org/tubedude/xirr.svg)](https://travis-ci.org/tubedude/xirr)[![Coverage Status](https://img.shields.io/coveralls/tubedude/xirr.svg)](https://coveralls.io/r/tubedude/xirr)[![Code Climate](https://codeclimate.com/github/tubedude/xirr/badges/gpa.svg)](https://codeclimate.com/github/tubedude/xirr)

This is a simple gem to calculate XIRR on Bisection Method based on this gist http://puneinvestor.wordpress.com/2013/10/01/calculate-xirr-in-ruby-bisection-method/
and ont Finance gem https://github.com/wkranec/finance

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
    cf << Transaction.new(-1000,  date: '2014-01-01'.to_time(:utc))
    cf << Transaction.new(-2000,  date: '2014-03-01'.to_time(:utc))
    cf << Transaction.new( 4500, date: '2015-12-01'.to_time(:utc))
    cf.xirr
    # 0.25159694345042327 # [Float]

## Contributing

1. Fork it ( https://github.com/tubedude/xirr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
