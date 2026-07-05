## Version 1.0.0
* New default solver: a safeguarded Newton (`rtsafe`) that brackets the root and
  falls back to a bisection step per iteration. It converges on flows the old
  Newton/bisection pair failed on — long maturities, low rates, and returns near
  -100% — without overflowing.
* `Cashflow#xirr` no longer silently returns `0.0` for a flow that does have a
  rate; the more robust solver now finds it. `Cashflow#xirr!` raises on an
  invalid flow or genuine non-convergence instead of returning
  `config.replace_for_nil`.
* Added `Cashflow#xnpv(rate)` and `Cashflow#mirr(finance_rate, reinvest_rate)`.
* Added periodic (dateless) helpers `Xirr.irr`, `Xirr.npv`, `Xirr.mirr` for
  amounts at equally spaced periods.
* Added the wider finance toolkit ported from the finance-elixir library:
  `Xirr::TVM` (`fv`, `pv`, `pmt`, `ipmt`, `ppmt`, `nper`, `rate`,
  `amortization_schedule`), `Xirr::Rates` (`effective_annual_rate`,
  `nominal_rate`, `continuous_to_periodic`), `Xirr::Bonds` (`price`, `ytm`,
  `duration`, `modified_duration`, `convexity`), `Xirr::Depreciation` (`sln`,
  `syd`, `ddb`, `db`), and `Xirr::Returns` (`volatility`, `cagr`,
  `payback_period`, `discounted_payback_period`, `profitability_index`, `twr`).
* Added an optional native (C) build of the rtsafe solver, selectable with
  `xirr(method: :rtsafe_c)`. It is best-effort: without a compiler the gem falls
  back to pure Ruby, and `Xirr::NATIVE` reports whether it loaded. Added a
  `benchmark/solvers.rb` comparing the solvers.
* Added a `:brent` solver (`xirr(method: :brent)`): derivative-free Brent's
  method over rtsafe's bracketing — as robust as rtsafe, and cheaper per
  iteration, which can help on very large cashflows.
* The `:bisection` and `:newton_method` methods are still available via
  `xirr(method:)`. `:newton_method` was reimplemented in plain Ruby, dropping the
  deprecated `bigdecimal/newton` standard library.
* Dropped the `bigdecimal` dependency entirely — results are `Float`, rounded to
  `config.precision`. (The solvers already computed in `Float`.)
* Removed the defunct Travis and Coveralls setup; added GitHub Actions CI.
* Allow activesupport 7 (Fixes #30). Breaking: require activesupport >= 6.1 and
  ruby >= 3.1.

## Version 0.7.0
* Removed `RubyInLine`
* Removed possibility to return false from `irr_guess`
* Removed global newton module
* Bumped dependencies

## Version 0.5.4
* Fallsback If Newton Methods returns NaN 

## Version 0.5.3
* Better tests
* added period option to Xirr

## Version 0.5.2
* Changed negative limits to return nil

## Version 0.5.1
* Newton Method will return nil if result is less than 100%

## Version 0.5.0
* This update will break the old Cashflow initializer
* Adds named attributes to Cashflow Initializer
* Allows specific configuration to initializer such as: period, flow (array of transactions)
* Calling xirr with a guess now requires named attribute
* If a method is provided, it won't fall back to the secondary method

## Version 0.4.1
* Added verification to pass on ruby 2.0.0

## Version 0.4.0

* Xirr returns nil and there is now a default settings to replace nil rate.
* It will compact the flow automatically, unless specified in the defaults.
* Attention to the new way, the Cashflow is created. Cashflow.new requires a Compacted boolean before the array of flow.

## Version 0.3.1

* Added fallback to secondary calculation method.

## Version 0.3.0

* Moved XNPV function to C.

## Version 0.2.9

* Cashflow validation excludes zeros

## Version 0.2.8

* Added missing tests
* Fixed Fallback method

## Version 0.2.7

* Bisection will now retry XIRR in Newton Method if right limit is reached
* Options in config are now module constants

## Version 0.2.6

* New Bisection method to avoid not converging to negative IRRs if not enough precision

## Version 0.2.5

* Default XIRR does not raise an Exception if cashflow is invalid

## Version 0.2.4

* Cashflow Invalid Messages are now public.
* Cashflow Invalid? won't raise exception
* Running XIRR in an invalid cashflow will throw exception
* New Cashflow No Exception XIRR call.

## Version 0.2.3

* Major fix to Bisection Engine.
* Error if provided method is wrong.
* Bisection: Initial guess is compared to default limits
* Transaction converts Time to Date.

## Version 0.2.2

* Added Tests.

## Version 0.2.1

* Output is rounded to default precision.

## Version 0.2.0

* Added Newton Method, but Bisection is still the default.
* Added new configs: precision, iteration limit.
* Raises a simple error if iteration limit is reached.
* Output is now BigDecimal.
* Fixed calculation of Bisection#npv
* Amounts in Transactions are now converted to Float
* Transactions now take Date Argument as Date instead of Time.
