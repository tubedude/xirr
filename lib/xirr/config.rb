# frozen_string_literal: true

require 'active_support/ordered_options'

module Xirr
  # The global settings, read and written as +Xirr.config.<key>+.
  #
  # This used to come from +ActiveSupport::Configurable+, which Rails 8.1
  # deprecates and Rails 8.2 removes. It was only ever a module-level
  # +ActiveSupport::OrderedOptions+, so that is what this returns.
  # @return [ActiveSupport::OrderedOptions]
  def self.config
    @config ||= ActiveSupport::OrderedOptions.new
  end

  # Yields {config} for block-style setup:
  #   Xirr.configure { |c| c.eps = 1.0e-8 }
  def self.configure
    yield config
  end

  # Default configuration. Each entry becomes both a config setting
  # (+Xirr.config.eps+) and a frozen constant of the same name upcased
  # (+Xirr::EPS+); the constant keeps the original default even after the setting
  # is reconfigured.
  default_values = {
    eps:             '1.0e-6'.to_f,
    period:          365.0,
    iteration_limit: 50,
    precision:       6,
    default_method:  :rtsafe,
    fallback:        true,
    replace_for_nil: 0.0,
    raise_exception: false
  }

  default_values.each do |key, value|
    config.public_send("#{key}=", value)
    const_set key.to_s.upcase.to_sym, value
  end
end
