## Version 0.2.8

* Added missing tests

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
