# frozen_string_literal: true

module Xirr
  # Expands [Array] to store a set of transactions which will be used to calculate the XIRR
  # @note A Cashflow should consist of at least two transactions, one positive and one negative.
  class Cashflow < Array
    attr_reader :raise_exception, :fallback, :iteration_limit, :options

    # @param args [Transaction]
    # @example Creating a Cashflow
    #   cf = Cashflow.new
    #   cf << Transaction.new( 1000, date: '2013-01-01'.to_date)
    #   cf << Transaction.new(-1234, date: '2013-03-31'.to_date)
    #   Or
    #   cf = Cashflow.new Transaction.new( 1000, date: '2013-01-01'.to_date), Transaction.new(-1234, date: '2013-03-31'.to_date)
    def initialize(flow: [], period: Xirr.config.period, ** options)
      @period   = period
      @fallback = options[:fallback] || Xirr.config.fallback
      @options  = options
      self << flow
      flatten!
    end

    # Check if Cashflow is invalid
    # @return [Boolean]
    def invalid?
      inflow.empty? || outflows.empty?
    end

    # Inverse of #invalid?
    # @return [Boolean]
    def valid?
      !invalid?
    end

    # @return [Float]
    # Sums all amounts in a cashflow
    def sum
      map(&:amount).sum
    end

    # Last investment date
    # @return [Time]
    def max_date
      @max_date ||= map(&:date).max
    end

    # A rough starting rate for the solver: the cash-on-cash multiple annualized
    # over the investment horizon, +multiple^(1 / years) - 1+.
    #
    # It falls back to 0.0 whenever that estimate is undefined or unusable — an
    # invalid or empty cashflow, a horizon of zero, a non-positive multiple, or a
    # rate at or below -100% (which the solver can't start from). The default
    # +rtsafe+ solver does not depend on this being accurate; it only needs a
    # finite rate above -1.
    # @return [Float]
    def irr_guess
      return @irr_guess = 0.0 unless valid?
      return @irr_guess = 0.0 if periods_of_investment.zero? || multiple <= 0

      guess = ((multiple**(1.0 / periods_of_investment)) - 1).round(3)
      @irr_guess = (guess.nan? || guess.infinite? || guess <= -1) ? 0.0 : guess
    end

    # @param guess [Float]
    # @param method [Symbol]
    # @return [Float] the rate, or +Xirr.config.replace_for_nil+ when it can't converge
    def xirr(guess: nil, method: nil, ** options)
      method, options = process_options(method, options)
      if invalid?
        raise ArgumentError, invalid_message if options[:raise_exception]
        return Xirr.config.replace_for_nil
      end

      result = choose_(method).send(:xirr, guess, options)
      # rtsafe already combines a Newton step with a bisection safeguard, so it is
      # the fallback for the fragile solvers; when it is itself the primary there
      # is nothing better to try, and a failure means the flow has no rate.
      if unconverged?(result) && fallback && method != :rtsafe && method != :rtsafe_c
        result = choose_(:rtsafe).send(:xirr, guess, options)
      end
      if unconverged?(result)
        raise ArgumentError, 'XIRR did not converge' if options[:raise_exception]
        return Xirr.config.replace_for_nil
      end
      result
    ensure
      # A per-call +period:+ must not leak into later #xnpv / #mirr calls.
      @temporary_period = nil
    end

    # Same as {#xirr}, but raises +ArgumentError+ when the cashflow is invalid or
    # the rate can't be found, instead of returning +Xirr.config.replace_for_nil+.
    # @return [Float]
    def xirr!(guess: nil, method: nil, ** options)
      xirr(guess: guess, method: method, **options.merge(raise_exception: true))
    end

    # Net present value of the dated flows discounted at +rate+ on the same
    # Actual/period basis {#xirr} uses. Roughly zero when +rate+ is the XIRR.
    # @param rate [Float]
    # @return [Float]
    def xnpv(rate)
      inject(0.0) { |sum, t| sum + t.amount / (1.0 + rate) ** ((t.date - min_date) / period) }
    end

    # Modified IRR of the dated flows. Positive flows are assumed reinvested at
    # +reinvest_rate+, negative flows financed at +finance_rate+. Unlike XIRR it
    # has a closed form and a single answer.
    # @param finance_rate [Float]
    # @param reinvest_rate [Float]
    # @return [Float]
    def mirr(finance_rate, reinvest_rate)
      raise ArgumentError, invalid_message if invalid?
      years = periods_of_investment
      raise ArgumentError, 'Flows span no time' if years.zero?

      future_of_inflows = 0.0
      present_of_outflows = 0.0
      each do |t|
        if t.amount > 0
          future_of_inflows += t.amount * (1.0 + reinvest_rate) ** ((max_date - t.date) / period)
        elsif t.amount < 0
          present_of_outflows += t.amount / (1.0 + finance_rate) ** ((t.date - min_date) / period)
        end
      end

      ((future_of_inflows / -present_of_outflows) ** (1.0 / years) - 1).round(Xirr.config.precision)
    end

    def process_options(method, options)
      @temporary_period         = options[:period]
      options[:raise_exception] = resolve_option(options, :raise_exception)
      options[:iteration_limit] = resolve_option(options, :iteration_limit)
      return switch_fallback(method), options
    end

    # Resolve an option in precedence order: this call, then the cashflow's own
    # options, then the global config. Reads +key?+ so an explicit +false+ or +0+
    # is honored rather than overwritten.
    # @return [Object]
    def resolve_option(options, key)
      return options[key] if options.key?(key)
      return @options[key] if @options.key?(key)

      Xirr.config.public_send(key)
    end

    # Providing a method turns off fallback; otherwise use the configured default
    # with fallback on. Returns the method to run.
    # @param method [Symbol]
    # @return [Symbol]
    def switch_fallback(method)
      if method
        @fallback = false
        method
      else
        @fallback = Xirr.config.fallback
        Xirr.config.default_method
      end
    end

    private :process_options, :resolve_option, :switch_fallback

    # A copy of the cashflow with same-date transactions merged into one.
    # @return [Cashflow]
    def compact_cf
      compact = Hash.new 0
      each { |flow| compact[flow.date] += flow.amount }
      Cashflow.new(flow: compact.map { |date, amount| Transaction.new(amount, date: date) }, period: period, **options)
    end

    # First investment date
    # @return [Time]
    def min_date
      @min_date ||= map(&:date).min
    end

    # @return [String]
    # Error message depending on the missing transaction
    def invalid_message
      return 'No positive transaction' if inflow.empty?
      return 'No negative transaction' if outflows.empty?
    end

    def period
      @temporary_period || @period
    end

    def <<(arg)
      super arg
      sort! { |x, y| x.date <=> y.date }
      # Adding a transaction can change the date range and leading sign, so drop
      # the values memoized from the old contents.
      @min_date = @max_date = @first_transaction_direction = nil
      self
    end

    private

    # @param method [Symbol]
    # Choose a Method to call.
    # @return [Class]
    def choose_(method)
      case method
      when :rtsafe
        RtSafe.new compact_cf
      when :brent
        Brent.new compact_cf
      when :rtsafe_c
        unless Xirr::NATIVE
          raise ArgumentError, 'the native :rtsafe_c extension is not compiled; ' \
                               'reinstall the gem with a C toolchain or run `rake compile`'
        end
        RtSafeC.new compact_cf
      when :bisection
        Bisection.new compact_cf
      when :newton_method
        NewtonMethod.new compact_cf
      else
        raise ArgumentError, "unknown method #{method.inspect}; use :rtsafe, :rtsafe_c, :brent, :bisection, or :newton_method"
      end
    end

    # A solver result that means "no rate found": nil, or a NaN.
    # @return [Boolean]
    def unconverged?(value)
      value.nil? || (value.respond_to?(:nan?) && value.nan?)
    end

    # @api private
    # Sorts the {Cashflow} by date ascending
    #   and finds the signal of the first transaction.
    # This implies the first transaction is a disbursement
    # @return [Integer]
    def first_transaction_direction
      @first_transaction_direction ||= first.amount / first.amount.abs
    end

    # Based on the direction of the first investment finds the multiple cash-on-cash
    # @example
    #   [100,100,-300] and [-100,-100,300] returns 1.5
    # @api private
    # @return [Float]
    def multiple
      inflow.sum(&:amount).abs / outflows.sum(&:amount).abs
    end

    def first_transaction_positive?
      first_transaction_direction > 0
    end

    # @api private
    # Counts how many years from first to last transaction in the cashflow
    # @return
    def periods_of_investment
      (max_date - min_date) / period
    end

    # @api private
    # @return [Array]
    # @see #outflows
    # Selects all positives transactions from Cashflow
    def inflow
      select { |x| x.amount * first_transaction_direction < 0 }
    end

    # @api private
    # @return [Array]
    # @see #inflow
    # Selects all negatives transactions from Cashflow
    def outflows
      select { |x| x.amount * first_transaction_direction > 0 }
    end
  end
end
