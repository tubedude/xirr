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
