module Xirr
  include ActiveSupport::Configurable

  # Sets as constants all the entries in the Hash Default values
  default_values = {
      eps: '1.0e-6'.to_f,
      days_in_year: 365,
      iteration_limit: 50,
      precision: 6,
      default_method: :bisection,
      fallback: true
  }

  # Iterates trhough default values and sets in config
  default_values.each do |key, value|
    self.config.send("#{key.to_sym}=", value)
    const_set key.to_s.upcase.to_sym, value
  end
end