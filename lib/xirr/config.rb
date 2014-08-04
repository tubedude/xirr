module Xirr
  include ActiveSupport::Configurable

  default_values = {
      eps: '1.0e-12',
      days_in_year: 365,
  }

  default_values.each do |key, value|
    self.config.send("#{key.to_sym}=", value)
  end
end
