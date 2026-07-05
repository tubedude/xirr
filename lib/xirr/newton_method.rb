# frozen_string_literal: true

module Xirr
  # Plain Newton-Raphson: step from the guess by -xnpv/xnpv' until the step is
  # smaller than the tolerance. Fast when it converges, but with no bracketing it
  # can walk off to a non-root or below -100%; {RtSafe} is the safeguarded default
  # that avoids that. Kept for `xirr(method: :newton_method)`.
  class NewtonMethod
    include Base

    # @param guess [Float, nil] initial rate
    # @param options [Hash] reads +:iteration_limit+
    # @return [Float, nil] the rate rounded to +Xirr.config.precision+, or nil
    def xirr(guess, options)
      limit = (options && options[:iteration_limit]) || Xirr.config.iteration_limit
      rate = (guess || cf.irr_guess).to_f

      limit.times do
        derivative = xnpv_derivative(rate)
        return nil if derivative.zero?

        step = xnpv(rate).to_f / derivative
        rate -= step
        # Below -100% the discount base (1 + rate) turns negative and the next
        # xnpv raises it to a fractional power, producing a Complex. Bail first.
        return nil if rate.nan? || rate.infinite? || rate <= -1
        break if step.abs < Xirr.config.eps
      end

      rate.nan? ? nil : rate.round(Xirr.config.precision)
    rescue FloatDomainError, Math::DomainError, RangeError
      nil
    end
  end
end
