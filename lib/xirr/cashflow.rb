module Xirr
  class Cashflow < Array
    include Xirr::Main

    def initialize(*args)
      args.each { |a| self << a }
      self.flatten!
    end

    def invalid?
      if positives.empty? || negatives.empty?
        raise ArgumentError, invalid_message
      else
        false
      end
    end

    def valid?
      !invalid?
    end

    def invalid_message
      return 'No positive transaction' if positives.empty?
      return 'No negatives transaction' if negatives.empty?
    end

    def educated_guess
      @educated_guess ||= ((multiple ** (1 / years_of_investment)) - 1).round(3)
    end

    def sum
      self.map(&:amount).sum
    end

    def irr_guess
      educated_guess
    end

    private

    def first_transaction_direction
      self.sort! { |x,y| x.date <=> y.date }
      self.first.amount / self.first.amount.abs
    end

    def multiple
      if first_transaction_direction > 0
        positives.sum(&:amount) / -negatives.sum(&:amount)
      else
        -negatives.sum(&:amount) / positives.sum(&:amount)
      end
    end

    def years_of_investment
      (max_date - min_date) / (365* 24 * 60 * 60)
    end

    def max_date
      @max_date ||= self.map(&:date).max
    end

    def min_date
      @min_date ||= self.map(&:date).min
    end

    def positives
      # return @positives if defined? @positives
      split_transactions
      @positives
    end

    def negatives
      # return @negatives if defined? @negatives
      split_transactions
      @negatives
    end

    def split_transactions
      @negatives, @positives = self.partition { |x| x.amount >= 0 } # Inverted as negative amount is good
    end

  end

end
