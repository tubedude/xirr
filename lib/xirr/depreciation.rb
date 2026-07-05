# frozen_string_literal: true

module Xirr
  # Writing an asset down from its +cost+ to its +salvage+ value over its +life+.
  # {sln} spreads the loss evenly; {syd}, {ddb}, and {db} are accelerated methods
  # that depreciate more early on and return the amount for a single +period+
  # (counting from 1).
  module Depreciation
    module_function

    # Straight-line depreciation: the equal amount the asset is written down by
    # each period.
    # @return [Float]
    def sln(cost, salvage, life)
      raise ArgumentError, 'life must be non-zero' if life.zero?

      (cost - salvage) / life * 1.0
    end

    # Sum-of-years'-digits depreciation for a single +period+ — an accelerated
    # method charging more in the early periods.
    # @return [Float]
    def syd(cost, salvage, life, period)
      raise ArgumentError, 'undefined' if life <= 0 || period < 1 || period > life

      (cost - salvage) * (life - period + 1) * 2.0 / (life * (life + 1))
    end

    # Double-declining-balance depreciation for a single +period+: each period
    # takes +factor/life+ of the remaining book value (never below +salvage+).
    # +factor+ defaults to 2 (the usual double-declining rate).
    # @return [Float]
    def ddb(cost, salvage, life, period, factor = 2)
      n = period.to_i
      unless life.positive? && factor.positive? && period == n && n >= 1 && n <= life
        raise ArgumentError, 'undefined'
      end

      declining_balance(cost, salvage, factor.to_f / life, n)
    end

    # Fixed-declining-balance depreciation for a single +period+. Like {ddb}, but
    # the rate is derived from +cost+, +salvage+, and +life+ (rounded to three
    # places, as spreadsheets do). +month+ is how many months the asset was in
    # service during its first year (default 12); a shorter first year spills the
    # remainder into an extra final period.
    # @return [Float]
    def db(cost, salvage, life, period, month = 12)
      n = period.to_i
      unless cost.positive? && salvage >= 0 && life.positive? && month >= 1 && month <= 12 &&
             period == n && n >= 1 && n <= life + 1
        raise ArgumentError, 'undefined'
      end

      fixed_declining(cost, salvage, life, n, month)
    end

    # --- helpers ------------------------------------------------------------

    # Walk periods 1..period carrying accumulated depreciation; return the amount
    # for the final period. Depreciation stops at the salvage floor.
    def declining_balance(cost, salvage, rate, period)
      accumulated = 0.0
      dep = 0.0
      (1..period).each do
        book = cost - accumulated
        dep = [[book * rate, book - salvage].min, 0.0].max
        accumulated += dep
      end
      dep
    end

    def fixed_declining(cost, salvage, life, period, month)
      rate = (1 - (salvage.to_f / cost)**(1.0 / life)).round(3)
      accumulated = 0.0
      dep = 0.0
      (1..period).each do |p|
        dep = db_period(cost, accumulated, rate, life, month, p)
        accumulated += dep
      end
      dep
    end

    def db_period(cost, accumulated, rate, life, month, period)
      return cost * rate * month / 12.0 if period == 1

      if period <= life
        (cost - accumulated) * rate
      else
        # The partial last period when the first year was shorter than 12 months.
        (cost - accumulated) * rate * (12 - month) / 12.0
      end
    end

    private_class_method :declining_balance, :fixed_declining, :db_period
  end
end
