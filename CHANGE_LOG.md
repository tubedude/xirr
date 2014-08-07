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
