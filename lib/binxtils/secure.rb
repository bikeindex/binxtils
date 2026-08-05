# frozen_string_literal: true

module Binxtils
  module Secure
    extend Functionable

    def compare?(value, expected)
      expected.present? && ActiveSupport::SecurityUtils.secure_compare(value.to_s, expected.to_s)
    end
  end
end
