# frozen_string_literal: true

module Xirr
  # Brent's method: a derivative-free root finder combining inverse quadratic
  # interpolation, the secant method, and bisection. It reuses {RtSafe}'s
  # bracketing, so it is as robust as the default solver but never evaluates the
  # NPV derivative — each iteration is cheaper, though it needs more of them.
  #
  # In practice it roughly ties {RtSafe}; it is offered for very large cashflows,
  # where the cheaper per-iteration cost can win. Select it with
  # `xirr(method: :brent)`. Unlike the Newton-based solvers it ignores the initial
  # guess — it works from the bracket.
  class Brent
    include Base

    # @param guess [Float, nil] ignored; Brent brackets the root itself
    # @param options [Hash] reads +:iteration_limit+
    # @return [Float, nil]
    def xirr(_guess, options)
      limit = (options && options[:iteration_limit]) || Xirr.config.iteration_limit
      Brent.find(flows, iteration_limit: limit)
    end

    # Pure solver over normalized +[time, amount]+ flows.
    # @param flows [Array<Array(Float, Float)>]
    # @return [Float, nil]
    def self.find(flows, tolerance: Xirr.config.eps, iteration_limit: Xirr.config.iteration_limit, precision: Xirr.config.precision)
      rate = zbrent(flows, tolerance.to_f, iteration_limit)
      return nil if rate.nil? || rate.nan? || rate.infinite?

      rounded = rate.round(precision)
      rounded <= -1.0 ? nil : rounded
    rescue FloatDomainError, Math::DomainError
      nil
    end

    # Bracket a sign change (reusing RtSafe), then iterate Brent's method within
    # it. Returns the rate, or nil if it can't bracket or converge.
    def self.zbrent(flows, tol, iteration_limit)
      low = RtSafe.safe_low(flows)
      f_low = RtSafe.present_value(flows, low)
      bounds = RtSafe.bracket(flows, low, f_low, 1.0)
      return nil if bounds.nil?

      a, b = bounds
      fa = f_low # a == low
      fb = RtSafe.present_value(flows, b)
      c = a
      fc = fa
      d = e = b - a

      iteration_limit.times do
        # Keep c as the contrapoint — opposite sign to b, so [b, c] brackets.
        if (fb.positive? && fc.positive?) || (fb.negative? && fc.negative?)
          c = a
          fc = fa
          d = e = b - a
        end
        # Ensure b is the better estimate.
        if fc.abs < fb.abs
          a = b
          b = c
          c = a
          fa = fb
          fb = fc
          fc = fa
        end

        tol1 = 2.0 * Float::EPSILON * b.abs + 0.5 * tol
        xm = 0.5 * (c - b)
        return b if xm.abs <= tol1 || fb.zero?

        if e.abs >= tol1 && fa.abs > fb.abs
          s = fb / fa
          if a == c
            # Secant step.
            p = 2.0 * xm * s
            q = 1.0 - s
          else
            # Inverse quadratic interpolation.
            q = fa / fc
            r = fb / fc
            p = s * (2.0 * xm * q * (q - r) - (b - a) * (r - 1.0))
            q = (q - 1.0) * (r - 1.0) * (s - 1.0)
          end
          q = -q if p.positive?
          p = p.abs
          min1 = 3.0 * xm * q - (tol1 * q).abs
          min2 = (e * q).abs
          if 2.0 * p < (min1 < min2 ? min1 : min2)
            e = d
            d = p / q # accept interpolation
          else
            d = e = xm # fall back to bisection
          end
        else
          d = e = xm # bounds decreasing too slowly; bisect
        end

        a = b
        fa = fb
        b += d.abs > tol1 ? d : (xm.positive? ? tol1 : -tol1)
        fb = RtSafe.present_value(flows, b)
      end
      nil
    end
  end
end
