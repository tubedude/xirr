module Xirr
  include ActiveSupport::Configurable

  # Default values
  default_values = {
      eps: '1.0e-12',
      days_in_year: 365,
      iteration_limit: 100,
      precision: 6
  }

  # Iterates trhough default values and sets in config
  default_values.each do |key, value|
    self.config.send("#{key.to_sym}=", value)
  end
end
