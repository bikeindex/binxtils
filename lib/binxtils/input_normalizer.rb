# frozen_string_literal: true

module Binxtils
  module InputNormalizer
    extend Functionable

    def boolean(param = nil)
      return false if param.blank?

      ActiveRecord::Type::Boolean.new.cast(param.to_s.strip)
    end

    def string(val)
      return nil if val.blank?

      val.to_s.delete("\u0000").strip.gsub(/\s+/, " ")
    end

    def present_or_false?(val)
      val.to_s.present?
    end

    def regex_escape(val)
      # Lazy hack, good enough for current purposes. Improve if required!
      string(val)&.gsub(/\W/, ".")
    end

    def sanitize(str = nil)
      Rails::Html::Sanitizer.full_sanitizer.new.sanitize(str.to_s, encode_special_chars: true)
        .strip
        .gsub("&amp;", "&") # ampersands are commonly used - keep them normal
        .gsub(/\s+/, " ") # remove extra whitespace
    end

    # Plain text, so unlike sanitize: every entity is decoded and angle brackets stay literal
    def plain_text(value = nil)
      normalize_whitespace(CGI.unescapeHTML(Rails::Html::Sanitizer.full_sanitizer.new.sanitize(value.to_s)))
    end

    # An HTML email's "blank" lines are often a &nbsp;, which String#strip doesn't count as whitespace
    def normalize_whitespace(value = nil)
      value.to_s.tr(" ", " ").lines.map(&:strip).join("\n").gsub(/\n{3,}/, "\n\n").strip
    end
  end
end
