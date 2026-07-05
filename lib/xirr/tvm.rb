# frozen_string_literal: true

module Xirr
  # Time-value-of-money scalars: {fv}, {pv}, {pmt}, {ipmt}, {ppmt}, {nper}, and
  # {rate}, plus an {amortization_schedule}. Each solves the standard annuity
  # equation for one unknown:
  #
  #   pv·(1+r)^n + pmt·(1 + r·type)·((1+r)^n − 1)/r + fv = 0
  #
  # +type+ is 0 for payments at the end of each period (an ordinary annuity) or 1
  # for the beginning (an annuity due). The sign convention follows spreadsheets:
  # money you receive is positive, money you pay out is negative.
  module TVM
    module_function

    # Future value: what an investment grows to after +nper+ periods, starting
    # from present value +pv+ with a fixed +pmt+ each period, compounding at
    # +rate+.
    # @return [Float]
    def fv(rate, nper, pmt, pv = 0.0, type = 0)
      validate_type!(type)
      if rate.zero?
        -(pv + pmt * nper) * 1.0
      else
        -(pv * (1 + rate)**nper + pmt * annuity(rate, nper, type)) * 1.0
      end
    end

    # Present value: what a stream of +pmt+ per period for +nper+ periods plus a
    # lump sum +fv+ at the end is worth today, discounted at +rate+.
    # @return [Float]
    def pv(rate, nper, pmt, fv = 0.0, type = 0)
      validate_type!(type)
      if rate.zero?
        -(fv + pmt * nper) * 1.0
      else
        -(fv + pmt * annuity(rate, nper, type)) / (1 + rate)**nper * 1.0
      end
    end

    # Level payment per period that pays off +pv+ (and reaches +fv+) over +nper+
    # periods at +rate+.
    # @return [Float]
    def pmt(rate, nper, pv, fv = 0.0, type = 0)
      validate_type!(type)
      raise ArgumentError, 'nper must be non-zero' if nper.zero?
      return -(pv + fv) / nper * 1.0 if rate.zero?

      -(pv * (1 + rate)**nper + fv) / annuity(rate, nper, type) * 1.0
    end

    # Interest portion of the payment in period +per+ (counting from 1). Pairs
    # with {ppmt}: the two add up to {pmt} for every period.
    # @return [Float]
    def ipmt(rate, per, nper, pv, fv = 0.0, type = 0)
      validate_type!(type)
      split_payment(rate, per, nper, pv, fv, type).first
    end

    # Principal portion of the payment in period +per+ (counting from 1). The
    # companion of {ipmt}.
    # @return [Float]
    def ppmt(rate, per, nper, pv, fv = 0.0, type = 0)
      validate_type!(type)
      split_payment(rate, per, nper, pv, fv, type).last
    end

    # Number of periods it takes for payments of +pmt+ to pay off +pv+ (reaching
    # +fv+) at +rate+.
    # @return [Float]
    def nper(rate, pmt, pv, fv = 0.0, type = 0)
      validate_type!(type)
      raise ArgumentError, 'undefined' if rate.zero? && pmt.zero?
      return -(pv + fv) / pmt * 1.0 if rate.zero?
      raise ArgumentError, 'undefined' if 1 + rate <= 0

      k = pmt * (1 + rate * type) / rate
      denom = pv + k
      raise ArgumentError, 'undefined' if denom.zero? || (k - fv) / denom <= 0

      Math.log((k - fv) / denom) / Math.log(1 + rate)
    end

    # Interest rate per period of an annuity of +nper+ payments of +pmt+, present
    # value +pv+, and future value +fv+. There is no closed form, so this reuses
    # the {RtSafe} solver.
    # @return [Float]
    def rate(nper, pmt, pv, fv = 0.0, type = 0, guess: 0.1)
      validate_type!(type)
      n = nper.to_i
      raise ArgumentError, 'nper must be a positive whole number' unless nper == n && n.positive?

      result = RtSafe.find(tvm_flows(n, pmt, pv, fv, type), guess: guess)
      raise ArgumentError, 'rate did not converge' if result.nil?

      result
    end

    # Full amortization schedule for a loan of +pv+ repaid with a level payment
    # over +nper+ periods at +rate+. Returns an array of row hashes with
    # +:period+, +:payment+, +:interest+, +:principal+, and +:balance+; the
    # balance runs from +pv+ down to exactly 0. Monetary columns are rounded to
    # +precision+ (default 2, i.e. cents).
    # @return [Array<Hash>]
    def amortization_schedule(rate, nper, pv, precision: 2)
      n = nper.to_i
      raise ArgumentError, 'nper must be a positive whole number' unless nper == n && n >= 1

      build_schedule(rate.to_f, n, pv.to_f, precision)
    end

    # --- helpers ------------------------------------------------------------

    def validate_type!(type)
      raise ArgumentError, 'type must be 0 (ordinary) or 1 (due)' unless type == 0 || type == 1
    end

    # (1 + r·type) · ((1+r)^n − 1) / r — the factor that multiplies pmt.
    def annuity(rate, nper, type)
      (1 + rate * type) * ((1 + rate)**nper - 1) / rate
    end

    # Split period +per+'s level payment into [interest, principal].
    def split_payment(rate, per, nper, pv, fv, type)
      n = per.to_i
      unless per == n && n >= 1 && n <= nper
        raise ArgumentError, 'per must be a whole number within 1..nper'
      end

      payment = pmt(rate, nper, pv, fv, type)
      balance = fv(rate, n - 1, payment, pv, type)
      interest = annuity_due_adjust(balance * rate, rate, n, type)
      # + 0.0 collapses a floating-point negative zero to 0.0.
      [interest + 0.0, payment - interest + 0.0]
    end

    # For an annuity due (type 1) the first period carries no interest and later
    # periods discount one step; an ordinary annuity (type 0) is left as-is.
    def annuity_due_adjust(interest, rate, per, type)
      return interest if type == 0
      return 0.0 if per == 1

      interest / (1 + rate)
    end

    # A TVM problem as a cash-flow series so {rate} can reuse the solver: +pv+ at
    # period 0, +pmt+ each period, +fv+ at the last period.
    def tvm_flows(nper, pmt, pv, fv, type)
      periods = type == 1 ? (0...nper) : (1..nper)
      acc = Hash.new(0.0)
      periods.each { |i| acc[i * 1.0] += pmt * 1.0 }
      acc[0.0] += pv * 1.0
      acc[nper * 1.0] += fv * 1.0
      acc.to_a
    end

    # Build the schedule in integer minor units (10^precision), so money is exact
    # and the balance ends at exactly zero, then convert back to floats.
    def build_schedule(rate, nper, pv, precision)
      scale = 10**precision
      payment = pmt(rate, nper, pv)
      rows = integer_schedule(rate, nper, (pv * scale).round, (payment * scale).round)
      rows.map do |period, pay, interest, principal, balance|
        {
          period:    period,
          payment:   pay / scale.to_f,
          interest:  interest / scale.to_f,
          principal: principal / scale.to_f,
          balance:   balance / scale.to_f
        }
      end
    end

    # Running balance in integer minor units; the final row pays off whatever
    # remains, so the balance ends at exactly 0.
    def integer_schedule(rate, nper, opening, payment)
      balance = opening
      (1..nper).map do |period|
        interest = (-balance * rate).round
        scheduled = period == nper ? -balance : payment - interest
        # Keep the balance retiring toward zero: never grow it and never overpay.
        principal = [[scheduled, -balance].max, 0].min
        balance += principal
        [period, interest + principal, interest, principal, balance]
      end
    end

    private_class_method :validate_type!, :annuity, :split_payment, :annuity_due_adjust,
                         :tvm_flows, :build_schedule, :integer_schedule
  end
end
