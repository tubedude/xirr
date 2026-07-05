# frozen_string_literal: true

module Xirr
  # True when the native rtsafe extension compiled and loaded.
  begin
    require 'xirr/xirr_native'
    NATIVE = true
  rescue LoadError
    NATIVE = false
  end

  # C-backed rtsafe. Same algorithm and results as {RtSafe}, run in a native
  # extension. Only usable when {NATIVE} is true (the extension was compiled);
  # otherwise the gem runs the pure-Ruby {RtSafe} instead.
  class RtSafeC
    include Base

    # @param guess [Float, nil]
    # @param options [Hash] reads +:iteration_limit+
    # @return [Float, nil]
    def xirr(guess, options)
      limit = (options && options[:iteration_limit]) || Xirr.config.iteration_limit
      start = (guess || cf.irr_guess).to_f
      rate = Xirr::Native.rtsafe(flows, start, Xirr.config.eps.to_f, limit)
      return nil if rate.nil?

      # Round before the floor check: a rate just above -1 can round down to it.
      rounded = rate.round(Xirr.config.precision)
      rounded <= -1.0 ? nil : rounded
    end
  end
end
