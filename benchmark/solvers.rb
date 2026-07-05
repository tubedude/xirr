# Benchmarks the solvers (rtsafe_c when the native extension is built, rtsafe,
# newton_method, bisection) across a range of cashflows: moderate, high-rate,
# long-horizon, near -100%, and a large flow.
#
#   ruby -Ilib benchmark/solvers.rb
#
# Reports average time per full `xirr` call and the value each solver returns
# (so speed can be read alongside whether the solver actually converged).

require 'active_support/all'
require 'xirr'
include Xirr

def cf(pairs)
  c = Cashflow.new
  pairs.each { |amount, date| c << Transaction.new(amount, date: date.to_date) }
  c
end

# --- test cashflows -------------------------------------------------------

monthly = [[-100_000, Date.new(1990, 1, 1)]]
360.times { |m| monthly << [650, Date.new(1990, 1, 1) >> (m + 1)] }

FLOWS = {
  'moderate (3 flows, ~0.23)'   => cf([[1000, '1985-01-01'], [-600, '1990-01-01'], [-6000, '1995-01-01']]),
  'high rate (~22)'             => cf([[1_000_000, '2020-01-01'], [-2_200_000, '2020-05-01'], [-800_000, '2020-06-01']]),
  'long horizon (56 yr)'        => cf([[-1000, '1957-01-01'], [390_000, '2013-01-01']]),
  'near -100%'                  => cf([[-10_000, '2014-04-15'], [305.6, '2014-05-15'], [500, '2014-10-19']]),
  'large (361 monthly flows)'   => cf(monthly),
}

METHODS = %i[rtsafe brent newton_method bisection]
METHODS.unshift(:rtsafe_c) if Xirr::NATIVE

# --- timing ---------------------------------------------------------------

def time_call(cashflow, method, iterations)
  # Warm up memoized dates / guess.
  cashflow.xirr(method: method)
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  iterations.times { cashflow.xirr(method: method) }
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  (elapsed / iterations) * 1_000.0 # ms per call
end

puts format('%-28s %-15s %12s  %s', 'cashflow', 'solver', 'ms/call', 'result')
puts '-' * 78

FLOWS.each do |name, cashflow|
  iterations = cashflow.size > 50 ? 200 : 5_000
  METHODS.each_with_index do |method, i|
    ms     = time_call(cashflow, method, iterations)
    result = cashflow.xirr(method: method)
    label  = i.zero? ? name : ''
    puts format('%-28s %-15s %12.4f  %s', label, method, ms, result)
  end
  puts
end
