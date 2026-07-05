# Xirr

[![Gem Version](https://badge.fury.io/rb/xirr.svg)](https://badge.fury.io/rb/xirr)
[![CI](https://github.com/tubedude/xirr/actions/workflows/ci.yml/badge.svg)](https://github.com/tubedude/xirr/actions/workflows/ci.yml)

Calculates the XIRR of a cashflow — the internal rate of return for
transactions that land on arbitrary dates, the way a spreadsheet's `XIRR` does.

The default solver is a safeguarded Newton method (`rtsafe`): it brackets the
root first, then takes a Newton step when that step stays inside the bracket and
a bisection step otherwise. That converges on flows the plain Newton or bisection
methods struggle with — long maturities, low rates, and returns near -100% — and
reports non-convergence instead of returning a wrong number. The `:bisection` and
`:newton_method` solvers remain available, and there is an optional native (C)
build of `rtsafe`. See [Choosing a solver](#choosing-a-solver).

## Installation

Add this line to your application's Gemfile:

    gem 'xirr'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install xirr

## Usage

```rb
include Xirr

cf = Xirr::Cashflow.new
cf << Xirr::Transaction.new(-1000,  date: '2014-01-01'.to_date)
cf << Xirr::Transaction.new(-2000,  date: '2014-03-01'.to_date)
cf << Xirr::Transaction.new( 4500, date: '2015-12-01'.to_date)
cf.xirr
# 0.251405 # Float, rounded to config.precision

flow = []
flow << Xirr::Transaction.new(-1000,  date: '2014-01-01'.to_date)
flow << Xirr::Transaction.new(-2000,  date: '2014-03-01'.to_date)
flow << Xirr::Transaction.new( 4500, date: '2015-12-01'.to_date)

cf = Xirr::Cashflow.new(flow: flow)
cf.xirr
```

`xirr` returns `config.replace_for_nil` (0.0 by default) when it can't find a
rate. Use `xirr!` when you would rather have an exception:

```rb
cf.xirr!                 # raises ArgumentError on an invalid or unsolvable flow
cf.xirr(method: :bisection)
```

### Related figures

```rb
cf.xnpv(0.1)             # net present value of the dated flows at a given rate
cf.mirr(0.10, 0.12)      # modified IRR: finance rate, then reinvestment rate
```

### Periodic (dateless) flows

When the flows fall at equally spaced periods and the exact dates don't matter,
work with a plain list of amounts. The rate is per period.

```rb
Xirr.irr([-1000, 1100])              # => 0.1
Xirr.npv(0.1, [-1000, 600, 600])     # => 41.322314
Xirr.mirr([-120_000, 39_000, 30_000, 21_000, 37_000, 46_000], 0.10, 0.12)
# => 0.126094
```

### More finance functions

Beyond cash-flow analysis, the gem carries the usual finance toolkit, grouped
into modules. Every function returns a plain number and raises `ArgumentError`
on inputs that have no answer.

```rb
# Time value of money — Xirr::TVM
Xirr::TVM.fv(0.05, 10, -100, -1000)          # => 2886.68 (future value)
Xirr::TVM.pmt(0.10, 10, 1000)                # => -162.75 (level payment)
Xirr::TVM.nper(0.05, -100, 1000)             # => 14.21   (number of periods)
Xirr::TVM.amortization_schedule(0.10 / 12, 12, 1000)
# => [{period: 1, payment: -87.92, interest: -8.33, principal: -79.59, balance: 920.41}, ...]

# Rate conversions — Xirr::Rates
Xirr::Rates.effective_annual_rate(0.10, 12)  # => 0.104713

# Fixed income — Xirr::Bonds
Xirr::Bonds.price(1000, 0.08, 0.10, 10)      # => 875.377897
Xirr::Bonds.ytm(1000, 0.08, 875.377897, 10)  # => 0.1
Xirr::Bonds.duration(0.06, 0.06, 3, 1)       # => 2.833393

# Depreciation — Xirr::Depreciation
Xirr::Depreciation.sln(10_000, 1_000, 5)     # => 1800.0
Xirr::Depreciation.ddb(10_000, 1_000, 5, 1)  # => 4000.0

# Performance & risk — Xirr::Returns
Xirr::Returns.cagr(1000, 2000, 10)           # => 0.071773
Xirr::Returns.twr([0.10, -0.05, 0.08])       # => 0.1286
Xirr::Returns.volatility([100, 102, 101, 103, 105]) # => 0.234528
```

## Choosing a solver

Four solvers are available; pick one per call with `method:`, or set a default
globally with `config.default_method`. They all return the same rate — they
differ in speed and robustness.

```rb
cf.xirr(method: :rtsafe)         # default: safeguarded Newton, pure Ruby
cf.xirr(method: :rtsafe_c)       # same algorithm, native C extension (optional)
cf.xirr(method: :brent)          # derivative-free; can win on very large flows
cf.xirr(method: :newton_method)  # plain Newton — fast, but guess-sensitive
cf.xirr(method: :bisection)      # robust on a bracketed flow, but slowest

Xirr.configure { |c| c.default_method = :rtsafe_c }
```

`:rtsafe` is the default because among the pure-Ruby solvers it is both the
fastest and the one that converges reliably — it combines a Newton step with a
bisection safeguard, so `:newton_method` and `:bisection` exist mainly for
comparison. `:rtsafe_c` is faster still but needs the native extension.

`:brent` shares rtsafe's bracketing, so it is just as robust, but is
derivative-free: cheaper per iteration at the cost of more of them. It roughly
ties rtsafe on ordinary flows and can pull ahead on very large cashflows, where
skipping the derivative pass matters.

### The optional native extension

The gem ships a C build of `rtsafe`. It is optional: if a compiler isn't
available at install time the gem falls back to the pure-Ruby solver, and nothing
about the public API changes. Check whether it loaded with `Xirr::NATIVE`;
selecting `:rtsafe_c` without it raises `ArgumentError`. Build it during
development with `rake compile`.

## Benchmark

Time per `xirr` call, averaged over many runs (Ruby 3.3.1). All four solvers
return the same rate; lower is faster. Reproduce with
`ruby -Ilib benchmark/solvers.rb`.

| Cashflow | `rtsafe_c` | `rtsafe` | `newton_method` | `bisection` |
| --- | ---: | ---: | ---: | ---: |
| moderate (3 flows)         | 0.04 ms | 0.06 ms | 0.10 ms | 0.40 ms |
| high rate (~22)            | 0.05 ms | 0.08 ms | 0.10 ms | 0.66 ms |
| long horizon (56 yr)       | 0.03 ms | 0.06 ms | 0.07 ms | 0.29 ms |
| near -100%                 | 0.06 ms | 0.11 ms | 0.12 ms | 0.29 ms |
| large (361 monthly flows)  | 2.59 ms | 4.05 ms | 8.10 ms | 40.4 ms |

`rtsafe` beats plain Newton and is several times faster than bisection, which
converges only linearly. The native `rtsafe_c` is roughly 1.5–2× faster again.

## Configuration

    # initializer/xirr.rb

    Xirr.configure do |config|
      config.eps    = 1.0e-12  # convergence tolerance on the rate (the step/interval size)
      config.period = 365.25   # days per year used to discount
    end

Other settings: `precision` (decimal places, default 6), `iteration_limit`
(default 50), `default_method` (default `:rtsafe`), `fallback` (default true),
`replace_for_nil` (returned when no rate is found, default 0.0), and
`raise_exception` (default false).


## Documentation

http://rubydoc.info/github/tubedude/xirr/master/frames

## Supported versions

    Ruby: >= 3.1
    ActiveSupport: >= 6.1, < 8

## Thanks

http://puneinvestor.wordpress.com/2013/10/01/calculate-xirr-in-ruby-bisection-method/
https://github.com/wkranec/finance

## Contributing

1. Fork it ( https://github.com/tubedude/xirr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run specs (`rake default`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
