module Xirr
  class Cashflow < Array
    include Xirr::Main

    def initialize(*args) # :nodoc:
      args.each { |a| self << a }
      self.flatten!
    end

    # Check if Cashflow is invalid and raises ArgumentError
    # retuns [Boolean]
    def invalid?
      if positives.empty? || negatives.empty?
        raise ArgumentError, invalid_message
      else
        false
      end
    end

    # Inverse of #invalid?
    # returns [Boolean]
    def valid?
      !invalid?
    end


    # calculates a simple IRR guess based on period of investment and multiples
    # returns [Float]
    def irr_guess
      ((multiple ** (1 / years_of_investment)) - 1).round(3)
    end

    def sum # :nodoc:
      self.map(&:amount).sum
    end

    private

    def first_transaction_direction # :nodoc:
      self.sort! { |x,y| x.date <=> y.date }
      self.first.amount / self.first.amount.abs
    end

    # Based on the direction of the first investment we create the multiple
    def multiple  # :nodoc:
      if first_transaction_direction > 0
        positives.sum(&:amount) / -negatives.sum(&:amount)
      else
        -negatives.sum(&:amount) / positives.sum(&:amount)
      end
    end

    def years_of_investment # :nodoc:
      (max_date - min_date) / (365 * 24 * 60 * 60).to_f
    end

    def max_date # :nodoc:
      @max_date ||= self.map(&:date).max
    end

    def min_date # :nodoc:
      @min_date ||= self.map(&:date).min
    end

    def positives # :nodoc:
      split_transactions
      @positives
    end

    def negatives # :nodoc:
      split_transactions
      @negatives
    end

    def split_transactions # :nodoc:
      @negatives, @positives = self.partition { |x| x.amount >= 0 } # Inverted as negative amount is good
    end

    def invalid_message # :nodoc:
      return 'No positive transaction' if positives.empty?
      return 'No negatives transaction' if negatives.empty?
    end

  end

end
