# frozen_string_literal: true

module Xirr
  # Safeguarded Newton-Raphson root finder — the classic +rtsafe+.
  #
  # It brackets a sign change of the net present value first, then each iteration
  # takes a Newton step when that step lands inside the bracket and is shrinking
  # the interval fast enough, and a bisection step otherwise. This keeps Newton's
  # speed on well-behaved flows while retaining bisection's guaranteed
  # convergence, in a single pass rather than running Newton to exhaustion and
  # then bisecting separately.
  #
  # The maintained bracket always encloses a sign change, so the result is a
  # genuine root rather than a stalled non-root, and a long-dated flow whose raw
  # Newton step would overflow takes a bisection step instead.
  class RtSafe
    include Base

    # Stop expanding the upper bound once it passes this — the flow has no root
    # in a sane rate range.
    BRACKET_CEILING = 1.0e7

    # Solves the compacted {Cashflow} the instance was built with.
    # @param guess [Float, nil] initial rate; used when it lands inside the bracket
    # @param options [Hash] reads +:iteration_limit+
    # @return [Float, nil] the rate rounded to +Xirr.config.precision+, or nil when it can't converge
    def xirr(guess, options)
      limit = (options && options[:iteration_limit]) || Xirr.config.iteration_limit
      start = guess || cf.irr_guess
      RtSafe.find(flows, guess: start.to_f, iteration_limit: limit)
    end

    # Pure solver over normalized +[time, amount]+ flows (time in years/periods).
    # Shared by the dated {Cashflow} path and the periodic {Xirr} module helpers.
    # @param flows [Array<Array(Float, Float)>]
    # @return [Float, nil]
    def self.find(flows, guess: 0.1, tolerance: Xirr.config.eps, iteration_limit: Xirr.config.iteration_limit, precision: Xirr.config.precision)
      rate = rtsafe(flows, guess.to_f, tolerance.to_f, iteration_limit)
      return nil if rate.nil? || rate.nan? || rate.infinite?

      # Round before the floor check: a rate just above -1 can round down to it.
      rounded = rate.round(precision)
      rounded <= -1.0 ? nil : rounded
    rescue FloatDomainError, Math::DomainError
      nil
    end

    # Net present value of +flows+ at +rate+: Σ amount / (1 + rate)^t
    def self.present_value(flows, rate)
      flows.inject(0.0) { |sum, (t, amount)| sum + amount / (1.0 + rate) ** t }
    end

    # Derivative of the NPV with respect to rate: Σ -t · amount / (1 + rate)^(t+1)
    def self.present_value_derivative(flows, rate)
      flows.inject(0.0) { |sum, (t, amount)| sum + (-t * amount / (1.0 + rate) ** (t + 1)) }
    end

    # Bracket a sign change, then run the safeguarded iteration from +guess+
    # (when it falls inside the bracket) or the midpoint.
    def self.rtsafe(flows, guess, tol, iteration_limit)
      low = safe_low(flows)
      f_low = present_value(flows, low)
      bounds = bracket(flows, low, f_low, 1.0)
      return nil if bounds.nil?

      a, b = bounds
      # a == low, so the NPV at a is f_low. Orient so it is negative at xlo and
      # positive at xhi — the invariant the step selection relies on.
      xlo, xhi = f_low < 0.0 ? [a, b] : [b, a]
      x = (guess > a && guess < b) ? guess : (a + b) / 2.0
      f = present_value(flows, x)
      df = present_value_derivative(flows, x)
      search(flows, x, xlo, xhi, f, df, (b - a).abs, tol, iteration_limit)
    end

    # Iterate to the root, taking a Newton or bisection step each time. Looped
    # (not recursed) so a large +iteration_limit+ can't overflow the stack.
    # @return [Float, nil] the root, or nil if it doesn't converge within +iters+
    def self.search(flows, x, xlo, xhi, f, df, dxold, tol, iters)
      iters.times do
        nxt, dx = move(x, xlo, xhi, f, df, dxold)
        return nxt if dx.abs < tol

        f = present_value(flows, nxt)
        df = present_value_derivative(flows, nxt)
        f < 0.0 ? xlo = nxt : xhi = nxt
        x = nxt
        dxold = dx
      end
      nil
    end

    # A Newton step when it's usable, a bisection step otherwise.
    # @return [Array(Float, Float)] +[next_x, step]+
    def self.move(x, xlo, xhi, f, df, dxold)
      if newton_usable?(x, xlo, xhi, f, df, dxold)
        dx = f / df
        [x - dx, dx]
      else
        dx = (xhi - xlo) / 2.0
        [xlo + dx, dx]
      end
    end

    # Prefer Newton when the derivative isn't flat, the step lands inside the
    # bracket, and it shrinks the interval by at least half. Comparing the Newton
    # point against the bracket — rather than the classic product form — avoids an
    # overflow in the steep zone near the bracket's floor. +df != 0+ short-circuits
    # before +x - f / df+.
    def self.newton_usable?(x, xlo, xhi, f, df, dxold)
      df != 0.0 && inside?(x - f / df, xlo, xhi) && (2.0 * f).abs <= (dxold * df).abs
    end

    def self.inside?(point, xlo, xhi)
      point >= [xlo, xhi].min && point <= [xlo, xhi].max
    end

    # The bracket's floor. As +rate+ nears -1, +(1 + rate)^t+ underflows to zero
    # (then divides by zero) for large +t+, so raise the floor just enough that the
    # longest-dated flow's discount factor stays finite. For short-dated flows this
    # is the familiar -0.999999; for a 30-year monthly schedule it sits higher.
    def self.safe_low(flows)
      max_t = flows.map { |t, _amount| t }.max
      max_t = 1.0 if max_t.nil? || max_t < 1.0
      [1.0e-290 ** (1.0 / max_t), 1.0e-6].max - 1.0
    end

    # Expand the upper bound until the NPV changes sign, giving a bracket.
    def self.bracket(flows, low, f_low, high)
      return nil if high > BRACKET_CEILING

      if straddles_zero?(f_low, present_value(flows, high))
        [low, high]
      else
        bracket(flows, low, f_low, high * 2 + 1)
      end
    end

    # Whether +a+ and +b+ sit on opposite sides of zero. Comparing signs rather
    # than the product +a * b+ avoids overflow when the NPV is astronomically large
    # near the bracket's floor for long-dated flows.
    def self.straddles_zero?(a, b)
      (a <= 0 && b >= 0) || (a >= 0 && b <= 0)
    end
  end
end
