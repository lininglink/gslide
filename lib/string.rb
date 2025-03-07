# frozen_string_literal: true

class String
  def snake_case
    gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

  def lower_camel_case
    split('_').inject { |m, p| m + p.capitalize }
  end
end

class Object
  def convert_keys(&blk)
    case self
      when Array
        self.map { |v| v.convert_keys(&blk) }
      when Hash
        self.map { |k, v| [blk.call(k), v.convert_keys(&blk)] }.to_h
      else
        self
    end
  end
end

# Now, you can do options.convert_keys { |k| k.lower_camel_case }
